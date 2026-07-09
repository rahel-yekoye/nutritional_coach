import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/meal_plan.dart';

class HiveSetup {
  static Future<void> init() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register adapters
    _registerAdapters();
    
    // NOTE: We no longer open global boxes here
    // User-specific boxes are opened in their respective services
    debugPrint('✅ Hive initialized with user-scoped storage');
  }

  static void _registerAdapters() {
    _safeRegister(UserProfileAdapter());
    _safeRegister(GenderAdapter());
    _safeRegister(ActivityLevelAdapter());
    _safeRegister(NutritionGoalAdapter());
    _safeRegister(BloodGroupAdapter()); // Add this line
    _safeRegister(NutritionLogAdapter());
    _safeRegister(FoodModelAdapter());
    _safeRegister(NutritionModelAdapter());
    _safeRegister(MealPlanAdapter());
    _safeRegister(MealItemAdapter());
    _safeRegister(MealTypeAdapter());
  }

  static void _safeRegister<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  /// Opens a user-specific box safely
  static Future<Box<T>> openUserBox<T>(String boxPrefix, String userId) async {
    final boxName = '${boxPrefix}_$userId';
    
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }
      
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('⚠️ Error opening user box $boxName: $e. Recreating...');
      
      // Close and delete corrupted box
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      
      // Create fresh box
      return await Hive.openBox<T>(boxName);
    }
  }

  /// Clears all data for a specific user
  static Future<void> clearUserData(String userId) async {
    final userBoxNames = [
      'userProfile_$userId',
      'nutritionLogs_$userId',
      'mealPlans_$userId',
    ];

    for (final boxName in userBoxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
        }
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('🗑️ Cleared user data box: $boxName');
      } catch (e) {
        debugPrint('⚠️ Error clearing box $boxName: $e');
      }
    }
  }

  /// Emergency function to clear ALL data (use only for debugging)
  static Future<void> clearAllData() async {
    try {
      // Get all box names that are currently open
      final openBoxes = <String>[];
      
      // First, collect names of open boxes
      try {
        // This is a workaround since getOpenBoxNames() doesn't exist in this Hive version
        if (Hive.isBoxOpen('userProfile')) openBoxes.add('userProfile');
        if (Hive.isBoxOpen('nutritionLogs')) openBoxes.add('nutritionLogs');
        if (Hive.isBoxOpen('mealPlans')) openBoxes.add('mealPlans');
        
        // Add user-specific box patterns that might exist
        for (int i = 0; i < 1000; i++) {
          final userId = 'user$i';
          final profileBox = 'userProfile_$userId';
          final nutritionBox = 'nutritionLogs_$userId';
          final mealBox = 'mealPlans_$userId';
          
          if (Hive.isBoxOpen(profileBox)) openBoxes.add(profileBox);
          if (Hive.isBoxOpen(nutritionBox)) openBoxes.add(nutritionBox);
          if (Hive.isBoxOpen(mealBox)) openBoxes.add(mealBox);
        }
      } catch (e) {
        debugPrint('Warning: Could not enumerate all boxes: $e');
      }
      
      // Close all open boxes first
      for (final boxName in openBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }
        } catch (e) {
          debugPrint('Warning: Could not close box $boxName: $e');
        }
      }
      
      // Delete all box files
      await Hive.deleteFromDisk();
      
      debugPrint('🧹 Cleared ALL Hive data');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
    }
  }

  /// Gets all box names for a specific user
  static List<String> getUserBoxNames(String userId) {
    return [
      'userProfile_$userId',
      'nutritionLogs_$userId',
      'mealPlans_$userId',
    ];
  }
}
