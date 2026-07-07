const jwt = require('jsonwebtoken');
const config = require('../config');

function signToken(payload) {
  return jwt.sign(payload, config.auth.jwtSecret, {
    expiresIn: config.auth.jwtExpiresIn,
  });
}

function verifyToken(token) {
  return jwt.verify(token, config.auth.jwtSecret);
}

module.exports = {
  signToken,
  verifyToken,
};
