const bcrypt = require('bcryptjs');

async function hashPassword(password) {
  const rounds = 12;
  return bcrypt.hash(password, rounds);
}

async function comparePassword(candidatePassword, hashedPassword) {
  return bcrypt.compare(candidatePassword, hashedPassword);
}

module.exports = {
  hashPassword,
  comparePassword,
};
