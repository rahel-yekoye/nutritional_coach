/**
 * Ethiopian Food Database - Search API Server
 * Production-ready Express.js application
 */

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const config = require('./config');
const { loadAllData } = require('./utils/dataLoader');
const { LRUCache } = require('./utils/cache');
const { requestLogger, logPerformanceMetrics } = require('./middleware/logger');
const { createRateLimiter } = require('./middleware/rateLimit');
const {
  notFoundHandler,
  errorHandler,
  handleUncaughtException,
  handleUnhandledRejection,
} = require('./middleware/errorHandler');
const FoodSearchRanker = require('./search_ranker');
const searchRoutes = require('./routes/search');
const foodRoutes = require('./routes/food');
const suggestRoutes = require('./routes/suggest');
const categoryRoutes = require('./routes/category');

// Handle uncaught exceptions and unhandled rejections
handleUncaughtException();
handleUnhandledRejection();

// Initialize Express app
const app = express();

// Trust proxy if configured (needed for rate limiting behind reverse proxy)
if (config.security.trustProxy) {
  app.set('trust proxy', 1);
}

// ======================
// MIDDLEWARE
// ======================

// Security middleware
if (config.security.helmetEnabled) {
  app.use(helmet());
}

// CORS
app.use(cors(config.cors));

// Body parsing
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Request logging
app.use(requestLogger);

// Rate limiting
app.use(createRateLimiter());

// ======================
// DATA INITIALIZATION
// ======================

let dataContext;

try {
  // Load all data at startup
  const {
    searchIndex,
    invertedIndex,
    foodCodeMap,
    categoryMap,
    keywordToFoodsMap,
    statistics,
    memoryUsage,
  } = loadAllData(
    config.dataFiles.searchIndex,
    config.dataFiles.invertedIndex
  );

  // Initialize search ranker with preloaded data
  const ranker = new FoodSearchRanker(searchIndex, invertedIndex, foodCodeMap);
  console.log('   ✓ Initialized FoodSearchRanker');

  // Create separate caches for different endpoints
  const searchCache = new LRUCache(config.cache.searchCacheSize, 'search');
  const suggestCache = new LRUCache(config.cache.suggestCacheSize, 'suggest');

  console.log(`   ✓ Initialized search cache: ${config.cache.searchCacheSize} entries`);
  console.log(`   ✓ Initialized suggest cache: ${config.cache.suggestCacheSize} entries`);

  // Build data context for routes
  dataContext = {
    searchIndex,
    invertedIndex,
    foodCodeMap,
    categoryMap,
    keywordToFoodsMap,
    ranker,
    searchCache,
    suggestCache,
    statistics,
  };

} catch (error) {
  console.error('\n❌ Fatal initialization error:', error.message);
  process.exit(1);
}

// ======================
// ROUTES
// ======================

// API routes
app.use('/search', searchRoutes(dataContext));
app.use('/food', foodRoutes(dataContext));
app.use('/suggest', suggestRoutes(dataContext));
app.use('/category', categoryRoutes(dataContext));

// Health check endpoint
app.get('/health', (req, res) => {
  const mem = process.memoryUsage();
  
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: config.server.env,
    data: {
      foods_loaded: dataContext.searchIndex.length,
      keywords_indexed: Object.keys(dataContext.invertedIndex).length,
      categories: Object.keys(dataContext.categoryMap).length,
    },
    cache: {
      search: dataContext.searchCache.getStats(),
      suggest: dataContext.suggestCache.getStats(),
    },
    memory: {
      heapUsed: `${(mem.heapUsed / 1024 / 1024).toFixed(2)} MB`,
      heapTotal: `${(mem.heapTotal / 1024 / 1024).toFixed(2)} MB`,
      rss: `${(mem.rss / 1024 / 1024).toFixed(2)} MB`,
    },
  });
});

// Root endpoint - API documentation
app.get('/', (req, res) => {
  res.json({
    name: 'Ethiopian Food Composition Table API',
    version: '1.0.0',
    description: 'Production-ready REST API for Ethiopian food composition data with intelligent search',
    documentation: 'https://github.com/your-repo/efct-api',
    endpoints: {
      search: {
        url: 'GET /search?q={query}&limit={limit}',
        description: 'Search foods by name, keywords, or category',
        example: '/search?q=barley&limit=10',
      },
      food: {
        url: 'GET /food/{food_code}',
        description: 'Get complete nutritional data for a specific food',
        example: '/food/010007',
      },
      suggest: {
        url: 'GET /suggest?q={query}',
        description: 'Get autocomplete suggestions for food names and keywords',
        example: '/suggest?q=wh',
      },
      health: {
        url: 'GET /health',
        description: 'Check API health status and statistics',
      },
    },
    statistics: dataContext.statistics,
  });
});

// Performance metrics endpoint (development only)
if (config.server.isDevelopment) {
  app.get('/metrics', (req, res) => {
    res.json({
      search_cache: dataContext.searchCache.getStats(),
      suggest_cache: dataContext.suggestCache.getStats(),
      memory: process.memoryUsage(),
      uptime: process.uptime(),
    });
  });
}

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// ======================
// SERVER STARTUP
// ======================

const server = app.listen(config.server.port, () => {
  console.log(`\n${'='.repeat(60)}`);
  console.log('✨ Ethiopian Food Database API - READY');
  console.log(`${'='.repeat(60)}`);
  console.log(`🌐 Server: http://localhost:${config.server.port}`);
  console.log(`📖 Docs: http://localhost:${config.server.port}/`);
  console.log(`🏥 Health: http://localhost:${config.server.port}/health`);
  console.log(`🔒 Environment: ${config.server.env.toUpperCase()}`);
  console.log(`${'='.repeat(60)}\n`);
});

// Log performance metrics every 5 minutes in production
if (config.server.isProduction) {
  setInterval(() => {
    logPerformanceMetrics();
    dataContext.searchCache.logStats();
    dataContext.suggestCache.logStats();
  }, 5 * 60 * 1000);
}

// Graceful shutdown
function gracefulShutdown(signal) {
  console.log(`\n📴 ${signal} received. Shutting down gracefully...`);
  
  server.close(() => {
    console.log('✓ HTTP server closed');
    
    // Log final statistics
    console.log('\n📊 Final Statistics:');
    dataContext.searchCache.logStats();
    dataContext.suggestCache.logStats();
    logPerformanceMetrics();
    
    console.log('\n👋 Goodbye!\n');
    process.exit(0);
  });

  // Force shutdown after 10 seconds
  setTimeout(() => {
    console.error('⚠️  Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = app;
