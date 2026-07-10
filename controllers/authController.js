const User = require('../models/User');
const { hashPassword, comparePassword } = require('../utils/password');
const { signToken } = require('../utils/jwt');

async function register(req, res, next) {
  try {
    const { fullName, email, password } = req.body;

    // DEBUG: Log registration attempt
    console.log(`[AUTH] Registration attempt for email: ${email}`);

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'fullName, email, and password are required',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log(`[AUTH] Registration failed - user already exists: ${email}`);
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists',
      });
    }

    // Create new user (setup NOT completed by default)
    const hashedPassword = await hashPassword(password);
    const user = await User.create({
      fullName,
      email,
      password: hashedPassword,
      hasCompletedSetup: false, // New users need to complete setup
      lastLogin: new Date(),
    });

    console.log(`[AUTH] New user created - ID: ${user._id}, Setup Required: ${!user.hasCompletedSetup}`);

    // Generate JWT token
    const token = signToken({ 
      id: user._id, 
      email: user.email,
      hasCompletedSetup: user.hasCompletedSetup,
    });

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        user: user.getPublicProfile(),
        token,
        needsSetup: user.needsSetup(),
      },
    });
  } catch (error) {
    console.error(`[AUTH] Registration error:`, error);
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    console.log(`[AUTH] Login attempt for email: ${email}`);

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      console.log(`[AUTH] Login failed - user not found: ${email}`);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Verify password
    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      console.log(`[AUTH] Login failed - invalid password: ${email}`);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    console.log(`[AUTH] Login successful - User ID: ${user._id}, Setup Completed: ${user.hasCompletedSetup}`);

    // Generate JWT token
    const token = signToken({ 
      id: user._id, 
      email: user.email,
      hasCompletedSetup: user.hasCompletedSetup,
    });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.getPublicProfile(),
        token,
        needsSetup: user.needsSetup(),
      },
    });
  } catch (error) {
    console.error(`[AUTH] Login error:`, error);
    next(error);
  }
}

async function completeSetup(req, res, next) {
  try {
    const userId = req.user._id;
    const {
      age,
      sex,
      height,
      weight,
      activityLevel,
      goal,
      fastingMode = false,
      bloodType,
    } = req.body;

    console.log(`[AUTH] Setup completion for user: ${userId}`);

    // Validate required setup fields
    if (!age || !sex || !height || !weight || !activityLevel || !goal) {
      return res.status(400).json({
        success: false,
        message: 'All setup fields are required: age, sex, height, weight, activityLevel, goal',
      });
    }

    // Update user with setup data
    const user = await User.findByIdAndUpdate(
      userId,
      {
        age,
        sex,
        height,
        weight,
        activityLevel,
        goal,
        fastingMode,
        ...(bloodType !== undefined && { bloodType }),
        hasCompletedSetup: true,
        setupCompletedAt: new Date(),
      },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    console.log(`[AUTH] Setup completed for user: ${userId}`);

    // Generate new token with updated setup status
    const token = signToken({ 
      id: user._id, 
      email: user.email,
      hasCompletedSetup: user.hasCompletedSetup,
    });

    res.json({
      success: true,
      message: 'Setup completed successfully',
      data: {
        user: user.getPublicProfile(),
        token,
        needsSetup: false,
      },
    });
  } catch (error) {
    console.error(`[AUTH] Setup completion error:`, error);
    next(error);
  }
}

async function getMe(req, res) {
  try {
    // User is already loaded by auth middleware, but get fresh data
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    console.log(`[AUTH] User data fetched - ID: ${user._id}, Setup: ${user.hasCompletedSetup}`);

    res.json({
      success: true,
      data: {
        user: user.getPublicProfile(),
        needsSetup: user.needsSetup(),
      },
    });
  } catch (error) {
    console.error(`[AUTH] Get user error:`, error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user data',
    });
  }
}

module.exports = {
  register,
  login,
  completeSetup,
  getMe,
};
