const User = require('../models/User');
const { hashPassword, comparePassword } = require('../utils/password');
const { signToken } = require('../utils/jwt');

async function register(req, res, next) {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'fullName, email, and password are required',
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User already exists',
      });
    }

    const hashedPassword = await hashPassword(password);
    const user = await User.create({
      fullName,
      email,
      password: hashedPassword,
    });

    const token = signToken({ id: user._id, email: user.email });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          profileCompleted: user.profileCompleted,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'email and password are required',
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    user.lastLogin = new Date();
    await user.save();

    const token = signToken({ id: user._id, email: user.email });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          profileCompleted: user.profileCompleted,
        },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function getMe(req, res) {
  res.json({
    success: true,
    data: {
      user: req.user,
    },
  });
}

module.exports = {
  register,
  login,
  getMe,
};
