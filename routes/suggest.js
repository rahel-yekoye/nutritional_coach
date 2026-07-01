/**
 * Autocomplete/Suggest Route Handler
 * GET /suggest?q=query
 */

const express = require('express');

module.exports = (dataContext) => {
  const router = express.Router();
  const { searchIndex, invertedIndex, suggestCache } = dataContext;

  /**
   * Sanitize input string
   */
  function sanitizeQuery(q) {
    if (typeof q !== 'string') {
      return '';
    }
    return q
      .trim()
      .substring(0, 50)  // Max 50 chars for suggest
      .toLowerCase()
      .replace(/[<>\"']/g, '');
  }

  /**
   * Calculate string similarity
   */
  function stringSimilarity(str1, str2) {
    const s1 = str1.toLowerCase();
    const s2 = str2.toLowerCase();
    
    if (s1 === s2) return 1;
    if (s1.startsWith(s2) || s2.startsWith(s1)) return 0.95;
    if (s1.includes(s2) || s2.includes(s1)) return 0.8;
    
    return 0;
  }

  /**
   * Get unique food names (for suggestions)
   */
  function getUniqueFoodNames() {
    const names = new Set();
    searchIndex.forEach(food => {
      names.add(food.food_name);
    });
    return Array.from(names);
  }

  /**
   * GET /suggest?q=query
   * Return top 5 autocomplete suggestions
   */
  router.get('/', (req, res) => {
    try {
      const { q } = req.query;

      if (!q || typeof q !== 'string') {
        return res.status(400).json({
          error: 'Bad request',
          message: 'Query parameter "q" is required',
          example: '/suggest?q=wh'
        });
      }

      const query = sanitizeQuery(q);
      if (query.length === 0) {
        return res.json({
          query: q,
          suggestions: [],
          timestamp: new Date().toISOString()
        });
      }

      // Check cache
      const cached = suggestCache.get(query);
      if (cached) {
        return res.json({
          ...cached,
          cached: true,
        });
      }

      const suggestions = new Set();

      // 1. Suggest food names
      const foodNames = getUniqueFoodNames();
      foodNames
        .filter(name => name.toLowerCase().startsWith(query))
        .slice(0, 3)
        .forEach(name => suggestions.add(name));

      // 2. Suggest keywords - OPTIMIZED: check if keyword is Set or Array
      Object.keys(invertedIndex)
        .filter(keyword => keyword.startsWith(query))
        .slice(0, 2)
        .forEach(keyword => suggestions.add(keyword));

      // 3. Fuzzy match if we don't have enough suggestions
      if (suggestions.size < 5) {
        foodNames
          .filter(name => stringSimilarity(name, query) > 0.7)
          .slice(0, 5 - suggestions.size)
          .forEach(name => suggestions.add(name));
      }

      // Format response
      const suggestionArray = Array.from(suggestions)
        .slice(0, 5)
        .map(suggestion => ({
          text: suggestion,
          type: invertedIndex[suggestion.toLowerCase()] ? 'keyword' : 'food_name'
        }));

      const response = {
        query: query,
        suggestions: suggestionArray,
        suggestion_count: suggestionArray.length,
        timestamp: new Date().toISOString()
      };

      // Cache result
      suggestCache.set(query, response);

      res.json(response);

    } catch (error) {
      console.error('Suggest error:', error);
      res.status(500).json({
        error: 'Suggestion failed',
        message: error.message
      });
    }
  });

  /**
   * GET /suggest/keywords?q=query
   * Return keyword suggestions for autocomplete
   */
  router.get('/keywords', (req, res) => {
    try {
      const { q } = req.query;

      if (!q || typeof q !== 'string') {
        return res.status(400).json({
          error: 'Bad request',
          message: 'Query parameter "q" is required',
          example: '/suggest/keywords?q=ce'
        });
      }

      const query = sanitizeQuery(q);
      if (query.length === 0) {
        return res.json({
          query: q,
          keywords: [],
          timestamp: new Date().toISOString()
        });
      }

      // Find matching keywords - handle both Set and Array
      const matchingKeywords = Object.keys(invertedIndex)
        .filter(keyword => keyword.startsWith(query))
        .sort((a, b) => {
          const aCount = invertedIndex[b] instanceof Set ? invertedIndex[b].size : invertedIndex[b].length;
          const bCount = invertedIndex[a] instanceof Set ? invertedIndex[a].size : invertedIndex[a].length;
          return aCount - bCount;
        })
        .slice(0, 10)
        .map(keyword => ({
          keyword: keyword,
          food_count: invertedIndex[keyword] instanceof Set ? invertedIndex[keyword].size : invertedIndex[keyword].length
        }));

      res.json({
        query: query,
        keywords: matchingKeywords,
        keyword_count: matchingKeywords.length,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Keyword suggest error:', error);
      res.status(500).json({
        error: 'Keyword suggestion failed',
        message: error.message
      });
    }
  });

  /**
   * GET /suggest/categories
   * Return all available categories
   */
  router.get('/categories', (req, res) => {
    try {
      const categories = {};
      searchIndex.forEach(food => {
        if (!categories[food.category]) {
          categories[food.category] = 0;
        }
        categories[food.category]++;
      });

      const categoriesList = Object.entries(categories)
        .map(([name, count]) => ({ name, food_count: count }))
        .sort((a, b) => b.food_count - a.food_count);

      res.json({
        categories: categoriesList,
        total_categories: categoriesList.length,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Category list error:', error);
      res.status(500).json({
        error: 'Category listing failed',
        message: error.message
      });
    }
  });

  return router;
};
