const User = require('../models/User');

async function getProfile(req, res, next) {
  try {
    res.json({
      success: true,
      data: {
        user: req.user,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function updateProfile(req, res, next) {
  try {
    const allowedFields = [
      'fullName',
      'age',
      'sex',
      'height',
      'weight',
      'activityLevel',
      'goal',
      'bloodType',
      'dailyCalories',
      'dailyProtein',
      'dailyFat',
      'dailyCarbs',
      'profilePicture',
      'appVersion',
      'device',
      'settings',
    ];

    const updates = {};
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid profile fields provided',
      });
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    }).select('-password');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getProfile,
  updateProfile,
};
