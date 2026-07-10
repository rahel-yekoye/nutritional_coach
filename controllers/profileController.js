const User = require('../models/User');

async function getProfile(req, res, next) {
  try {
    // Get fresh user data from database (not from token)
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    console.log(`[PROFILE] Profile fetched for user: ${user._id}`);

    res.json({
      success: true,
      data: {
        user: user.getPublicProfile(),
        needsSetup: user.needsSetup(),
      },
    });
  } catch (error) {
    console.error(`[PROFILE] Get profile error:`, error);
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
      'fastingMode',
      'bloodType',
      'profilePicture',
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
        message: 'No valid fields provided for update',
      });
    }

    console.log(`[PROFILE] Updating profile for user: ${req.user._id}`, Object.keys(updates));

    const user = await User.findByIdAndUpdate(
      req.user._id, 
      updates, 
      {
        new: true,
        runValidators: true,
      }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: user.getPublicProfile(),
      },
    });
  } catch (error) {
    console.error(`[PROFILE] Update profile error:`, error);
    next(error);
  }
}

module.exports = {
  getProfile,
  updateProfile,
};
