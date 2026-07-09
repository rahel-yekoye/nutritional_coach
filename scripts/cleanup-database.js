const mongoose = require('mongoose');
const User = require('../models/User');
const MealLog = require('../models/MealLog');

async function cleanupDatabase() {
  try {
    console.log('🗑️  Starting database cleanup...\n');

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ethiopian-food-db');
    console.log('✅ Connected to MongoDB');

    // Show current counts before deletion
    const userCount = await User.countDocuments();
    const mealCount = await MealLog.countDocuments();
    
    console.log('\n📊 Current database contents:');
    console.log(`   Users: ${userCount}`);
    console.log(`   Meal Logs: ${mealCount}`);

    if (userCount === 0 && mealCount === 0) {
      console.log('\n✨ Database is already clean!');
      return;
    }

    // Ask for confirmation
    console.log('\n⚠️  WARNING: This will permanently delete ALL users and meal logs!');
    console.log('Press Ctrl+C to cancel, or wait 5 seconds to continue...');
    
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Delete all meal logs first (they reference users)
    if (mealCount > 0) {
      console.log('\n🗑️  Deleting all meal logs...');
      const deletedMeals = await MealLog.deleteMany({});
      console.log(`✅ Deleted ${deletedMeals.deletedCount} meal logs`);
    }

    // Delete all users
    if (userCount > 0) {
      console.log('\n🗑️  Deleting all users...');
      const deletedUsers = await User.deleteMany({});
      console.log(`✅ Deleted ${deletedUsers.deletedCount} users`);
    }

    // Verify deletion
    console.log('\n✅ Verifying cleanup...');
    const remainingUsers = await User.countDocuments();
    const remainingMeals = await MealLog.countDocuments();
    
    console.log('\n📊 Final database contents:');
    console.log(`   Users: ${remainingUsers}`);
    console.log(`   Meal Logs: ${remainingMeals}`);

    if (remainingUsers === 0 && remainingMeals === 0) {
      console.log('\n🎉 Database cleanup successful!');
      console.log('All users and meal logs have been permanently deleted.');
    } else {
      console.log('\n❌ Cleanup incomplete!');
      console.log('Some data may still remain in the database.');
    }

  } catch (error) {
    console.error('\n❌ Database cleanup failed:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Additional function to show database stats without deleting
async function showDatabaseStats() {
  try {
    console.log('📊 Checking database contents...\n');

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ethiopian-food-db');
    console.log('✅ Connected to MongoDB');

    // Get counts
    const userCount = await User.countDocuments();
    const mealCount = await MealLog.countDocuments();
    
    console.log('\n📊 Current database contents:');
    console.log(`   Users: ${userCount}`);
    console.log(`   Meal Logs: ${mealCount}`);

    if (userCount > 0) {
      console.log('\n👤 Recent users:');
      const recentUsers = await User.find({})
        .select('fullName email createdAt')
        .sort({ createdAt: -1 })
        .limit(5);
      
      recentUsers.forEach(user => {
        console.log(`   - ${user.fullName} (${user.email}) - ${user.createdAt.toLocaleDateString()}`);
      });
    }

    if (mealCount > 0) {
      console.log('\n🍽️  Recent meal logs:');
      const recentMeals = await MealLog.find({})
        .select('foodName calories createdAt userId')
        .sort({ createdAt: -1 })
        .limit(5);
      
      recentMeals.forEach(meal => {
        console.log(`   - ${meal.foodName} (${meal.calories} kcal) - User: ${meal.userId}`);
      });
    }

  } catch (error) {
    console.error('\n❌ Failed to check database:', error.message);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Check command line arguments
const command = process.argv[2];

if (command === 'stats' || command === '--stats' || command === '-s') {
  showDatabaseStats();
} else if (command === 'cleanup' || command === '--cleanup' || command === '-c' || !command) {
  cleanupDatabase();
} else {
  console.log(`
🗑️  Database Cleanup Utility

Usage:
  node scripts/cleanup-database.js [command]

Commands:
  cleanup, -c    Delete ALL users and meal logs (default)
  stats, -s      Show database statistics without deleting

Examples:
  node scripts/cleanup-database.js           # Delete everything
  node scripts/cleanup-database.js cleanup   # Delete everything
  node scripts/cleanup-database.js stats     # Just show stats
`);
  process.exit(0);
}