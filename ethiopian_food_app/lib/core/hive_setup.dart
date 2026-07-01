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

    // Open and validate boxes
    await _openAndValidateBox<UserProfile>('userProfile');
    await _openAndValidateBox<NutritionLog>('nutritionLogs');
    await _openAndValidateBox<MealPlan>('mealPlans');
  }

  static void _registerAdapters() {
    _safeRegister(UserProfileAdapter());
    _safeRegister(GenderAdapter());
    _safeRegister(ActivityLevelAdapter());
    _safeRegister(NutritionGoalAdapter());
    _safeRegister(BloodGroupAdapter());
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

  static Future<void> _openAndValidateBox<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        Hive.box<T>(boxName);
      } else {
        final box = await Hive.openBox(boxName);
        for (final value in box.values) {
          if (value is! T) {
            throw HiveError(
              'Type mismatch in $boxName: expected $T but found ${value.runtimeType}',
            );
          }
        }

        await box.close();
        await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      debugPrint('Hive Error opening $boxName: $e. Recreating box...');
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
    }
  }

  static Future<void> clearAllData() async {
    if (Hive.isBoxOpen('userProfile')) await Hive.box('userProfile').close();
    if (Hive.isBoxOpen('nutritionLogs')) await Hive.box('nutritionLogs').close();
    if (Hive.isBoxOpen('mealPlans')) await Hive.box('mealPlans').close();

    await Hive.deleteBoxFromDisk('userProfile');
    await Hive.deleteBoxFromDisk('nutritionLogs');
    await Hive.deleteBoxFromDisk('mealPlans');
  }
}
