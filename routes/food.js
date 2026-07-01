/**
 * Food Details Route Handler
 * GET /food/:food_code
 */

const express = require('express');

module.exports = (dataContext) => {
  const router = express.Router();
  const { foodCodeMap } = dataContext;

  /**
   * Validate food code format
   */
  function isValidFoodCode(code) {
    return /^[0-9]{6}$/.test(code);
  }

  /**
   * GET /food/:food_code
   * Get full details for a specific food
   */
  router.get('/:food_code', (req, res) => {
    try {
      const { food_code } = req.params;

      // Validate food code format
      if (!isValidFoodCode(food_code)) {
        return res.status(400).json({
          error: 'Invalid food code',
          message: 'Food code must be 6 digits',
          example: '/food/010007',
          received: food_code
        });
      }

      // Look up food
      const food = foodCodeMap[food_code];
      if (!food) {
        return res.status(404).json({
          error: 'Not found',
          message: `No food found with code ${food_code}`,
          food_code: food_code
        });
      }

      // Format response
      const response = {
        food_code: food.food_code,
        food_name: food.food_name,
        food_name_original: food.food_name_original,
        food_name_amharic: food.food_name_amharic,
        normalized_amharic: food.normalized_amharic,
        category: food.category,
        keywords: food.keywords,
        nutrition: {
          energy_kcal: food.energy_kcal,
          protein_g: food.protein_g,
          fat_g: food.fat_g,
          carbs_g: food.carbs_g,
          fiber_g: food.fiber_g,
          water_g: food.water_g,
          ash_g: food.ash_g
        },
        timestamp: new Date().toISOString()
      };

      res.json(response);

    } catch (error) {
      console.error('Food lookup error:', error);
      res.status(500).json({
        error: 'Lookup failed',
        message: error.message
      });
    }
  });

  /**
   * GET /food/by-name/:name
   * Get foods by partial name match
   */
  router.get('/by-name/:name', (req, res) => {
    try {
      const { name } = req.params;
      const query = name.trim().toLowerCase();

      if (query.length < 2) {
        return res.status(400).json({
          error: 'Invalid name',
          message: 'Name query must be at least 2 characters',
          example: '/food/by-name/barley'
        });
      }

      // Find matching foods from foodCodeMap
      const matches = Object.values(foodCodeMap).filter(food =>
        food.food_name.toLowerCase().includes(query) ||
        food.normalized_amharic.includes(query)
      );

      res.json({
        query,
        count: matches.length,
        results: matches.slice(0, 50) // Limit results
      });

    } catch (error) {
      console.error('Food name lookup error:', error);
      res.status(500).json({
        error: 'Lookup failed',
        message: error.message
      });
    }
  });

  /**
   * GET /food/compare/list
   * Compare multiple foods by their codes
   * Query: ?codes=010001,010002
   */
  router.get('/compare/list', (req, res) => {
    try {
      const { codes } = req.query;
      
      if (!codes) {
        return res.status(400).json({
          error: 'Missing codes',
          message: 'Provide comma-separated food codes in "codes" query parameter'
        });
      }

      const foodCodes = codes.split(',').filter(code => code.trim().length > 0);
      
      if (foodCodes.length === 0) {
        return res.status(400).json({
          error: 'Invalid codes',
          message: 'Provide at least one valid food code'
        });
      }

      const results = foodCodes.map(code => {
        const food = foodCodeMap[code];
        if (!food) return { food_code: code, error: 'Not found' };
        
        return {
          food_code: food.food_code,
          food_name: food.food_name,
          category: food.category,
          nutrition: {
            energy_kcal: food.energy_kcal,
            protein_g: food.protein_g,
            fat_g: food.fat_g,
            carbs_g: food.carbs_g,
            fiber_g: food.fiber_g
          }
        };
      });

      res.json({
        count: results.length,
        results
      });

    } catch (error) {
      console.error('Compare error:', error);
      res.status(500).json({
        error: 'Comparison failed',
        message: error.message
      });
    }
  });

  return router;
};
