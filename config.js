/**
 * Configuration file for Ethiopian Food Database API
 * Centralizes all environment variables and configuration settings
 */

require('dotenv').config();

module.exports = {
  // Server Configuration
  server: {
    port: parseInt(process.env.PORT, 10) || 3000,
    env: process.env.NODE_ENV || 'development',
    isDevelopment: process.env.NODE_ENV !== 'production',
    isProduction: process.env.NODE_ENV === 'production',
  },

  // Database Configuration
  db: {
    uri: process.env.MONGODB_URI || '',
    options: {
      serverSelectionTimeoutMS: parseInt(process.env.MONGODB_SERVER_SELECTION_TIMEOUT_MS, 10) || 5000,
      maxPoolSize: parseInt(process.env.MONGODB_MAX_POOL_SIZE, 10) || 10,
    },
  },

  // Authentication Configuration
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS, 10) || 12,
  },

  // Cache Configuration
  cache: {
    maxSize: parseInt(process.env.CACHE_MAX_SIZE, 10) || 1000,
    searchCacheSize: parseInt(process.env.SEARCH_CACHE_SIZE, 10) || 500,
    suggestCacheSize: parseInt(process.env.SUGGEST_CACHE_SIZE, 10) || 500,
    ttl: parseInt(process.env.CACHE_TTL, 10) || 3600000, // 1 hour in ms
  },

  // Rate Limiting Configuration
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 60000, // 1 minute
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
    message: 'Too many requests from this IP, please try again later.',
  },

  // CORS Configuration
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: process.env.CORS_CREDENTIALS === 'true',
  },

  // Data Files
  dataFiles: {
    searchIndex: process.env.SEARCH_INDEX_PATH || './search_index.json',
    invertedIndex: process.env.INVERTED_INDEX_PATH || './cleaned_inverted_index.json',
  },

  // Search Configuration
  search: {
    maxQueryLength: parseInt(process.env.MAX_QUERY_LENGTH, 10) || 200,
    maxResultsLimit: parseInt(process.env.MAX_RESULTS_LIMIT, 10) || 100,
    defaultLimit: parseInt(process.env.DEFAULT_SEARCH_LIMIT, 10) || 20,
  },

  // Security
  security: {
    helmetEnabled: process.env.HELMET_ENABLED !== 'false',
    trustProxy: process.env.TRUST_PROXY === 'true',
  },

  // Logging
  logging: {
    enableRequestLogging: process.env.ENABLE_REQUEST_LOGGING !== 'false',
    enableCacheLogging: process.env.ENABLE_CACHE_LOGGING === 'true',
    enablePerformanceLogging: process.env.ENABLE_PERFORMANCE_LOGGING !== 'false',
  },
};
