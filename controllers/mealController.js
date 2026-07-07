const MealLog = require('../models/MealLog');

async function createMealLog(req, res, next) {
  try {
    const meal = await MealLog.create({
      userId: req.user._id,
      ...req.body,
    });

    res.status(201).json({
      success: true,
      message: 'Meal log created successfully',
      data: {
        meal,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function listMealLogs(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const skip = parseInt(req.query.skip, 10) || 0;

    const meals = await MealLog.find({ userId: req.user._id })
      .sort({ consumedAt: -1 })
      .skip(skip)
      .limit(limit);

    res.json({
      success: true,
      data: {
        meals,
        count: meals.length,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function getMealSummary(req, res, next) {
  try {
    const summary = await MealLog.aggregate([
      { $match: { userId: req.user._id } },
      {
        $group: {
          _id: null,
          totalCalories: { $sum: '$calories' },
          totalProtein: { $sum: '$protein' },
          totalFat: { $sum: '$fat' },
          totalCarbs: { $sum: '$carbs' },
          totalMeals: { $sum: 1 },
        },
      },
    ]);

    res.json({
      success: true,
      data: {
        summary: summary[0] || {
          totalCalories: 0,
          totalProtein: 0,
          totalFat: 0,
          totalCarbs: 0,
          totalMeals: 0,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createMealLog,
  listMealLogs,
  getMealSummary,
};
