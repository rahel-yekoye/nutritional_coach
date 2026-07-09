const jwt = require('jsonwebtoken');
const config = require('../config');
const User = require('../models/User');

async function protect(req, res, next) {
  try {
    let token;

    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer ')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route',
      });
    }

    const decoded = jwt.verify(token, config.auth.jwtSecret);
    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      console.log(`[AUTH] Protected route access denied - user not found for ID: ${decoded.id}`);
      return res.status(401).json({
        success: false,
        message: 'User not found',
      });
    }

    // DEBUG: Log which user is accessing protected routes
    console.log(`[AUTH] Protected route accessed by user ID: ${user._id}, email: ${user.email}`);

    req.user = user;
    next();
  } catch (error) {
    console.error(`[AUTH] Token verification error:`, error);
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token',
    });
  }
}

module.exports = protect;
