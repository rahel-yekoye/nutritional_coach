/**
 * Search Route Handler
 * GET /search?q=query&limit=20
 */

const express = require('express');

module.exports = (dataContext) => {
  const router = express.Router();
  const { searchIndex, ranker, searchCache } = dataContext;

  /**
   * Sanitize input string
   */
  function sanitizeQuery(q) {
    if (typeof q !== 'string') {
      return '';
    }
    return q
      .trim()
      .substring(0, 200)  // Max 200 chars
      .replace(/[<>\"']/g, '');  // Remove dangerous chars
  }

  /**
   * Generate cache key
   */
  function getCacheKey(query, limit) {
    return `${query}:${limit}`;
  }

  /**
   * GET /search?q=query&limit=20
   * Search for foods by query string
   */
  router.get('/', (req, res) => {
    try {
      const { q, limit = 20 } = req.query;

      // Validate input
      if (!q || typeof q !== 'string') {
        return res.status(400).json({
          error: 'Bad request',
          message: 'Query parameter "q" is required and must be a string',
          example: '/search?q=barley'
        });
      }

      const query = sanitizeQuery(q);
      if (query.length === 0) {
        return res.status(400).json({
          error: 'Bad request',
          message: 'Query must not be empty',
          example: '/search?q=barley'
        });
      }

      const parsedLimit = Math.min(parseInt(limit) || 20, 100);  // Cap at 100

      // Check cache
      const cacheKey = getCacheKey(query, parsedLimit);
      const cached = searchCache.get(cacheKey);
      
      if (cached) {
        return res.json({
          ...cached,
          cached: true,
        });
      }

      // Perform search
      const results = ranker.search(query, parsedLimit);

      // Format response
      const response = {
        query: query,
        result_count: results.length,
        limit: parsedLimit,
        results: results.map(result => ({
          food_code: result.food_code,
          food_name: result.food_name,
          food_name_amharic: result.food_name_amharic,
          category: result.category,
          score: parseFloat(result.score.toFixed(2)),
          scoreBreakdown: {
            nameMatch: parseFloat(result.nameScore.toFixed(1)),
            keywordMatch: parseFloat(result.keywordScore.toFixed(1)),
            categoryMatch: parseFloat(result.categoryScore.toFixed(1))
          },
          matchType: result.matchType,
          keywords: result.keywords.slice(0, 5),
          nutrition: {
            energy_kcal: result.energy_kcal,
            protein_g: result.protein_g,
            fat_g: result.fat_g,
            carbs_g: result.carbs_g,
            fiber_g: result.fiber_g
          }
        })),
        timestamp: new Date().toISOString()
      };

      // Cache result
      searchCache.set(cacheKey, response);

      res.json(response);

    } catch (error) {
      console.error('Search error:', error);
      res.status(500).json({
        error: 'Search failed',
        message: error.message
      });
    }
  });

  return router;
};
