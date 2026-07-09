const { connectDatabase } = require('./config/db');
const User = require('./models/User');

async function clearAllUsers() {
  try {
    console.log('🔄 Connecting to MongoDB...');
    await connectDatabase();
    
    console.log('🗑️ Deleting all users...');
    const result = await User.deleteMany({});
    
    console.log(`✅ Deleted ${result.deletedCount} users`);
    console.log('🎉 All users cleared successfully!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error clearing users:', error);
    process.exit(1);
  }
}

clearAllUsers();