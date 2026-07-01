/**
 * Global Error Handler Middleware
 * Centralized error handling for all routes
 */

const config = require('../config');

/**
 * Custom error class for API errors
 */
class ApiError extends Error {
  constructor(statusCode, message, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Error handler for 404 Not Found
 */
function notFoundHandler(req, res, next) {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString(),
    available_endpoints: [
      'GET /search?q=query',
      'GET /food/:food_code',
      'GET /suggest?q=query',
      'GET /health',
      'GET /'
    ]
  });
}

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, next) {
  // Default to 500 if no status code is set
  const statusCode = err.statusCode || 500;
  const isOperational = err.isOperational || false;

  // Log error details
  if (!isOperational || statusCode >= 500) {
    console.error('\n❌ Error occurred:');
    console.error('   Path:', req.path);
    console.error('   Method:', req.method);
    console.error('   Status:', statusCode);
    console.error('   Message:', err.message);
    
    if (config.server.isDevelopment) {
      console.error('   Stack:', err.stack);
    }
    console.error('');
  }

  // Build error response
  const errorResponse = {
    error: err.name || 'Error',
    message: err.message || 'An error occurred',
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString(),
  };

  // Add details in development mode
  if (config.server.isDevelopment) {
    errorResponse.stack = err.stack;
    errorResponse.details = err.details;
  }

  // Add details for operational errors even in production
  if (isOperational && err.details) {
    errorResponse.details = err.details;
  }

  // Send error response
  res.status(statusCode).json(errorResponse);
}

/**
 * Async error wrapper
 * Wraps async route handlers to catch errors
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/**
 * Validation error handler
 */
function validationError(message, details = null) {
  return new ApiError(400, message, details);
}

/**
 * Not found error handler
 */
function notFoundError(resource, identifier) {
  return new ApiError(404, `${resource} not found: ${identifier}`);
}

/**
 * Internal server error handler
 */
function internalError(message = 'Internal server error') {
  return new ApiError(500, message);
}

/**
 * Handle uncaught exceptions
 */
function handleUncaughtException() {
  process.on('uncaughtException', (err) => {
    console.error('\n🔥 UNCAUGHT EXCEPTION! Shutting down...');
    console.error('Error:', err.name, err.message);
    console.error('Stack:', err.stack);
    process.exit(1);
  });
}

/**
 * Handle unhandled promise rejections
 */
function handleUnhandledRejection() {
  process.on('unhandledRejection', (err) => {
    console.error('\n🔥 UNHANDLED REJECTION! Shutting down...');
    console.error('Error:', err);
    process.exit(1);
  });
}

module.exports = {
  ApiError,
  notFoundHandler,
  errorHandler,
  asyncHandler,
  validationError,
  notFoundError,
  internalError,
  handleUncaughtException,
  handleUnhandledRejection,
};
