/**
 * Request Logging Middleware
 * Logs request timing, method, path, status code, and response time
 */

const config = require('../config');

/**
 * Format bytes to human readable
 */
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Format duration to human readable
 */
function formatDuration(ms) {
  if (ms < 1) return '<1ms';
  if (ms < 1000) return `${Math.round(ms)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

/**
 * Get color code for status
 */
function getStatusColor(statusCode) {
  if (statusCode >= 500) return '\x1b[31m'; // Red
  if (statusCode >= 400) return '\x1b[33m'; // Yellow
  if (statusCode >= 300) return '\x1b[36m'; // Cyan
  if (statusCode >= 200) return '\x1b[32m'; // Green
  return '\x1b[0m'; // Reset
}

/**
 * Request timing logger middleware
 */
function requestLogger(req, res, next) {
  if (!config.logging.enableRequestLogging) {
    return next();
  }

  // Start timing
  const startTime = Date.now();
  const startMem = process.memoryUsage().heapUsed;

  // Capture request start
  req.startTime = startTime;
  req.requestId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  // Log when response finishes
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const memUsed = process.memoryUsage().heapUsed - startMem;
    const timestamp = new Date().toISOString();
    
    // Color code status
    const statusColor = getStatusColor(res.statusCode);
    const resetColor = '\x1b[0m';

    // Build log message
    let logMessage = `${timestamp} | ${req.method.padEnd(4)} ${req.path.padEnd(30)} | `;
    logMessage += `${statusColor}${res.statusCode}${resetColor} | `;
    logMessage += `${formatDuration(duration).padEnd(6)}`;

    // Add memory usage if significant
    if (Math.abs(memUsed) > 1024 * 100) { // > 100KB
      logMessage += ` | mem: ${formatBytes(Math.abs(memUsed))}`;
    }

    // Add query params if present
    if (Object.keys(req.query).length > 0) {
      const queryStr = new URLSearchParams(req.query).toString();
      logMessage += ` | query: ${queryStr.substring(0, 50)}`;
    }

    console.log(logMessage);

    // Warn on slow requests (>500ms)
    if (config.logging.enablePerformanceLogging && duration > 500) {
      console.warn(`⚠️  Slow request: ${req.method} ${req.path} took ${formatDuration(duration)}`);
    }
  });

  next();
}

/**
 * Performance metrics logger
 */
function logPerformanceMetrics() {
  const mem = process.memoryUsage();
  const uptime = process.uptime();

  console.log('\n📊 Performance Metrics:');
  console.log(`   Uptime: ${formatDuration(uptime * 1000)}`);
  console.log(`   Heap Used: ${formatBytes(mem.heapUsed)} / ${formatBytes(mem.heapTotal)}`);
  console.log(`   RSS: ${formatBytes(mem.rss)}`);
  console.log(`   External: ${formatBytes(mem.external)}`);
}

/**
 * Cache statistics logger
 */
function createCacheLogger(cacheName) {
  return {
    logHit: (key) => {
      if (config.logging.enableCacheLogging) {
        console.log(`✓ Cache hit [${cacheName}]: ${key}`);
      }
    },
    logMiss: (key) => {
      if (config.logging.enableCacheLogging) {
        console.log(`✗ Cache miss [${cacheName}]: ${key}`);
      }
    },
    logEviction: (key) => {
      if (config.logging.enableCacheLogging) {
        console.log(`⟳ Cache eviction [${cacheName}]: ${key}`);
      }
    },
    logStats: (cache) => {
      console.log(`📦 Cache stats [${cacheName}]: ${cache.size} entries`);
    }
  };
}

module.exports = {
  requestLogger,
  logPerformanceMetrics,
  createCacheLogger,
  formatBytes,
  formatDuration,
};
