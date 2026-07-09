/**
 * Middleware to ensure user has completed initial setup
 * Redirects to setup completion if not done
 */
function requireSetup(req, res, next) {
  try {
    const user = req.user;
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    // Check if user has completed setup
    if (!user.hasCompletedSetup) {
      console.log(`[SETUP] User ${user._id} needs to complete setup`);
      return res.status(200).json({
        success: true,
        requiresSetup: true,
        message: 'User setup required',
        data: {
          user: {
            id: user._id,
            fullName: user.fullName,
            email: user.email,
            hasCompletedSetup: false,
          },
          needsSetup: true,
        },
      });
    }

    // User has completed setup, continue
    next();
  } catch (error) {
    console.error('[SETUP] Setup check error:', error);
    res.status(500).json({
      success: false,
      message: 'Setup verification failed',
    });
  }
}

module.exports = requireSetup;