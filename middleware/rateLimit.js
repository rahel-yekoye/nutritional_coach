/**
 * Rate Limiting Middleware
 * Implements per-IP rate limiting using in-memory store
 */

const config = require('../config');

/**
 * Simple in-memory rate limiter
 */
class RateLimiter {
  constructor(windowMs, maxRequests) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    this.requests = new Map(); // IP -> [{timestamp}]
    
    // Cleanup old entries every minute
    setInterval(() => this.cleanup(), 60000);
  }

  /**
   * Check if request should be allowed
   */
  checkLimit(ip) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    // Get existing requests for this IP
    let ipRequests = this.requests.get(ip) || [];

    // Remove requests outside the window
    ipRequests = ipRequests.filter(timestamp => timestamp > windowStart);

    // Check if limit exceeded
    if (ipRequests.length >= this.maxRequests) {
      return {
        allowed: false,
        remaining: 0,
        resetTime: ipRequests[0] + this.windowMs,
      };
    }

    // Add current request
    ipRequests.push(now);
    this.requests.set(ip, ipRequests);

    return {
      allowed: true,
      remaining: this.maxRequests - ipRequests.length,
      resetTime: now + this.windowMs,
    };
  }

  /**
   * Cleanup old entries
   */
  cleanup() {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    for (const [ip, requests] of this.requests.entries()) {
      const validRequests = requests.filter(timestamp => timestamp > windowStart);
      
      if (validRequests.length === 0) {
        this.requests.delete(ip);
      } else {
        this.requests.set(ip, validRequests);
      }
    }
  }

  /**
   * Get stats
   */
  getStats() {
    return {
      totalIPs: this.requests.size,
      windowMs: this.windowMs,
      maxRequests: this.maxRequests,
    };
  }
}

/**
 * Create rate limiter middleware
 */
function createRateLimiter(options = {}) {
  const windowMs = options.windowMs || config.rateLimit.windowMs;
  const maxRequests = options.maxRequests || config.rateLimit.maxRequests;
  const message = options.message || config.rateLimit.message;

  const limiter = new RateLimiter(windowMs, maxRequests);

  return (req, res, next) => {
    // Get client IP
    const ip = req.ip || req.connection.remoteAddress;

    // Check rate limit
    const result = limiter.checkLimit(ip);

    // Set rate limit headers
    res.setHeader('X-RateLimit-Limit', maxRequests);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', new Date(result.resetTime).toISOString());

    if (!result.allowed) {
      const retryAfter = Math.ceil((result.resetTime - Date.now()) / 1000);
      
      res.setHeader('Retry-After', retryAfter);
      
      console.warn(`⚠️  Rate limit exceeded for IP: ${ip}`);
      
      return res.status(429).json({
        error: 'Too Many Requests',
        message: message,
        retryAfter: retryAfter,
        limit: maxRequests,
        window: `${windowMs / 1000} seconds`,
        timestamp: new Date().toISOString(),
      });
    }

    next();
  };
}

/**
 * Create custom rate limiter for specific routes
 */
function createCustomRateLimiter(maxRequests, windowMs = 60000) {
  return createRateLimiter({
    maxRequests,
    windowMs,
    message: `Rate limit: ${maxRequests} requests per ${windowMs / 1000} seconds`,
  });
}

module.exports = {
  createRateLimiter,
  createCustomRateLimiter,
  RateLimiter,
};
