/**
 * LRU Cache Implementation
 * Least Recently Used cache with automatic eviction
 */

const { createCacheLogger } = require('../middleware/logger');

/**
 * LRU Cache class
 */
class LRUCache {
  constructor(maxSize, name = 'default') {
    this.maxSize = maxSize;
    this.name = name;
    this.cache = new Map();
    this.logger = createCacheLogger(name);
    this.stats = {
      hits: 0,
      misses: 0,
      evictions: 0,
      sets: 0,
    };
  }

  /**
   * Get value from cache
   */
  get(key) {
    if (!this.cache.has(key)) {
      this.stats.misses++;
      this.logger.logMiss(key);
      return null;
    }

    // Move to end (mark as recently used)
    const value = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, value);

    this.stats.hits++;
    this.logger.logHit(key);
    return value;
  }

  /**
   * Set value in cache
   */
  set(key, value) {
    // Remove if already exists (to reorder)
    if (this.cache.has(key)) {
      this.cache.delete(key);
    }

    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize) {
      const oldestKey = this.cache.keys().next().value;
      this.cache.delete(oldestKey);
      this.stats.evictions++;
      this.logger.logEviction(oldestKey);
    }

    this.cache.set(key, value);
    this.stats.sets++;
  }

  /**
   * Check if key exists
   */
  has(key) {
    return this.cache.has(key);
  }

  /**
   * Clear cache
   */
  clear() {
    this.cache.clear();
    this.stats = {
      hits: 0,
      misses: 0,
      evictions: 0,
      sets: 0,
    };
  }

  /**
   * Get cache size
   */
  get size() {
    return this.cache.size;
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const totalRequests = this.stats.hits + this.stats.misses;
    const hitRate = totalRequests > 0 ? (this.stats.hits / totalRequests * 100).toFixed(2) : 0;

    return {
      name: this.name,
      size: this.cache.size,
      maxSize: this.maxSize,
      hits: this.stats.hits,
      misses: this.stats.misses,
      evictions: this.stats.evictions,
      sets: this.stats.sets,
      hitRate: `${hitRate}%`,
      utilizationRate: `${(this.cache.size / this.maxSize * 100).toFixed(2)}%`,
    };
  }

  /**
   * Log cache statistics
   */
  logStats() {
    const stats = this.getStats();
    console.log(`\n📦 Cache Statistics [${this.name}]:`);
    console.log(`   Size: ${stats.size} / ${stats.maxSize}`);
    console.log(`   Hit Rate: ${stats.hitRate}`);
    console.log(`   Hits: ${stats.hits} | Misses: ${stats.misses}`);
    console.log(`   Evictions: ${stats.evictions} | Sets: ${stats.sets}`);
    console.log(`   Utilization: ${stats.utilizationRate}`);
  }

  /**
   * Get all keys
   */
  keys() {
    return Array.from(this.cache.keys());
  }

  /**
   * Delete specific key
   */
  delete(key) {
    return this.cache.delete(key);
  }
}

/**
 * Create cache with TTL support
 */
class TTLCache extends LRUCache {
  constructor(maxSize, ttl, name = 'ttl-cache') {
    super(maxSize, name);
    this.ttl = ttl; // Time to live in milliseconds
    this.timestamps = new Map();
    
    // Cleanup expired entries every minute
    this.cleanupInterval = setInterval(() => this.cleanup(), 60000);
  }

  /**
   * Set value with timestamp
   */
  set(key, value) {
    super.set(key, value);
    this.timestamps.set(key, Date.now());
  }

  /**
   * Get value if not expired
   */
  get(key) {
    const timestamp = this.timestamps.get(key);
    
    if (timestamp && Date.now() - timestamp > this.ttl) {
      // Expired
      this.cache.delete(key);
      this.timestamps.delete(key);
      this.stats.misses++;
      return null;
    }

    return super.get(key);
  }

  /**
   * Cleanup expired entries
   */
  cleanup() {
    const now = Date.now();
    let cleaned = 0;

    for (const [key, timestamp] of this.timestamps.entries()) {
      if (now - timestamp > this.ttl) {
        this.cache.delete(key);
        this.timestamps.delete(key);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      console.log(`🧹 Cleaned ${cleaned} expired entries from cache [${this.name}]`);
    }
  }

  /**
   * Clear cache and timestamps
   */
  clear() {
    super.clear();
    this.timestamps.clear();
  }

  /**
   * Stop cleanup interval
   */
  destroy() {
    clearInterval(this.cleanupInterval);
  }
}

module.exports = {
  LRUCache,
  TTLCache,
};
