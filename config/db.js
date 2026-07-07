const mongoose = require('mongoose');
const config = require('../config');

async function connectDatabase() {
  if (!config.db.uri) {
    console.warn('⚠️  MongoDB URI not configured. Skipping database connection.');
    return null;
  }

  try {
    await mongoose.connect(config.db.uri, config.db.options);
    console.log('✅ MongoDB connected');
    return mongoose.connection;
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    throw error;
  }
}

module.exports = {
  connectDatabase,
};
