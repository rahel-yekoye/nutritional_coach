/**
 * Category Route Handler
 * GET /category/:categoryName
 */

const express = require('express');

module.exports = (dataContext) => {
  const router = express.Router();
  const { searchIndex, categoryMap } = dataContext;

  /**
   * GET /category/:categoryName
   * Get all foods in a specific category
   */
  router.get('/:categoryName', (req, res) => {
    try {
      const { categoryName } = req.params;
      const decodedCategory = decodeURIComponent(categoryName);

      // Find foods in this category
      const categoryFoods = searchIndex.filter(food => 
        food.category.toLowerCase() === decodedCategory.toLowerCase()
      );

      if (categoryFoods.length === 0) {
        return res.status(404).json({
          error: 'Category not found',
          message: `No foods found in category: ${decodedCategory}`,
          category: decodedCategory
        });
      }

      // Format response
      const response = {
        category: categoryFoods[0].category, // Use actual category name
        count: categoryFoods.length,
        foods: categoryFoods.map(food => ({
          food_code: food.food_code,
          food_name: food.food_name,
          food_name_amharic: food.food_name_amharic,
          category: food.category,
          keywords: food.keywords,
          nutrition: {
            energy_kcal: food.energy_kcal,
            protein_g: food.protein_g,
            fat_g: food.fat_g,
            carbs_g: food.carbs_g,
            fiber_g: food.fiber_g
          }
        })),
        timestamp: new Date().toISOString()
      };

      res.json(response);

    } catch (error) {
      console.error('Category lookup error:', error);
      res.status(500).json({
        error: 'Lookup failed',
        message: error.message
      });
    }
  });

  return router;
};
