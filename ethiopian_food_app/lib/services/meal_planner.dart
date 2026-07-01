import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ethiopian_food_app/core/models/meal_plan.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/unified_nutrition_state.dart';

class MealPlannerService {
  static const String _boxName = 'mealPlans';
  static const String _planKey = 'currentMealPlan';

  Box<MealPlan>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<MealPlan>(_boxName);
    } else {
      _box = Hive.box<MealPlan>(_boxName);
    }
  }

  MealPlan? getPersistedMealPlan() {
    try {
      final data = _box?.get(_planKey);
      if (data != null && data is! MealPlan) {
        print('Warning: Found incompatible data in mealPlans box: ${data.runtimeType}. Deleting...');
        _box?.delete(_planKey);
        return null;
      }
      return data;
    } catch (e) {
      print('Error reading meal plan from Hive: $e');
      return null;
    }
  }

  Future<void> saveMealPlan(MealPlan plan) async {
    await _box?.put(_planKey, plan);
  }

  MealPlan generateMealPlan({
    required List<FoodModel> allFoods,
    required UnifiedNutritionState state,
  }) {
    // Filter foods based on fasting mode
    final availableFoods = state.isFasting
        ? _filterFastingFoods(allFoods)
        : allFoods;

    // Logic for dynamic meal planning:
    // We look at remaining macros. If any macro is already over limit (remaining < 0),
    // we prioritize foods that are low in that macro.
    
    final remaining = state.remaining;
    
    // Distribute remaining calories across the "unfilled" meals.
    // Since we don't track which specific meal was logged, we'll assume a standard distribution
    // of the remaining allowance.
    
    final targetCalories = max(remaining.calories, 100.0); // At least 100 kcal for suggestions
    final targetProtein = max(remaining.protein, 5.0);

    // Distribution: Breakfast 25%, Lunch 45%, Dinner 30% of REMAINING
    // This makes the plan adapt as the day goes on.
    
    final breakfast = _generateMeal(
      availableFoods: availableFoods,
      targetCalories: targetCalories * 0.25,
      targetProtein: targetProtein * 0.25,
      goal: state.goal,
      bloodGroup: state.bloodGroup,
      mealType: MealType.breakfast,
      remaining: remaining,
    );

    final lunch = _generateMeal(
      availableFoods: availableFoods,
      targetCalories: targetCalories * 0.45,
      targetProtein: targetProtein * 0.45,
      goal: state.goal,
      bloodGroup: state.bloodGroup,
      mealType: MealType.lunch,
      remaining: remaining,
    );

    final dinner = _generateMeal(
      availableFoods: availableFoods,
      targetCalories: targetCalories * 0.30,
      targetProtein: targetProtein * 0.30,
      goal: state.goal,
      bloodGroup: state.bloodGroup,
      mealType: MealType.dinner,
      remaining: remaining,
    );

    // Calculate totals
    final totalCalories = _sumCalories([...breakfast, ...lunch, ...dinner]);
    final totalProtein = _sumProtein([...breakfast, ...lunch, ...dinner]);
    final totalCarbs = _sumCarbs([...breakfast, ...lunch, ...dinner]);
    final totalFat = _sumFat([...breakfast, ...lunch, ...dinner]);
    final totalFiber = _sumFiber([...breakfast, ...lunch, ...dinner]);

    final plan = MealPlan(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFiber,
      generatedAt: DateTime.now(),
    );

    saveMealPlan(plan);
    return plan;
  }

  List<FoodModel> _filterFastingFoods(List<FoodModel> foods) {
    final excludedCategories = {
      'Meat & Poultry',
      'Fish & Seafood',
      'Dairy & Milk Products',
      'Eggs & Egg Products',
    };

    return foods
        .where((food) => !excludedCategories.contains(food.category))
        .toList();
  }

  List<MealItem> _generateMeal({
    required List<FoodModel> availableFoods,
    required double targetCalories,
    required double targetProtein,
    required NutritionGoal goal,
    required BloodGroup bloodGroup,
    required MealType mealType,
    required NutritionValues remaining,
  }) {
    final mealItems = <MealItem>[];

    // Define food preferences based on meal type
    List<String> preferredCategories;
    switch (mealType) {
      case MealType.breakfast:
        preferredCategories = [
          'Cereals & Grains',
          'Fruits',
          'Legumes & Pulses',
          'Beverages',
        ];
        break;
      case MealType.lunch:
        preferredCategories = [
          'Legumes & Pulses',
          'Vegetables',
          'Cereals & Grains',
          'Meat & Poultry',
          'Fish & Seafood',
        ];
        break;
      case MealType.dinner:
        preferredCategories = [
          'Vegetables',
          'Legumes & Pulses',
          'Cereals & Grains',
        ];
        break;
    }

    // Filter foods by preferred categories
    var candidateFoods = availableFoods
        .where((food) =>
            preferredCategories.contains(food.category) &&
            food.nutrition != null)
        .toList();

    if (candidateFoods.isEmpty) {
      candidateFoods = availableFoods.where((food) => food.nutrition != null).toList();
    }

    // ADAPTIVE SCORING:
    // Score each food based on how well it fits the REMAINING allowance.
    // Penalty for macros that are already over limit.
    // Bonus for macros that are under target.
    // ADDED: Bonus for foods matching Blood Group preferences.
    
    final scoredFoods = candidateFoods.map((food) {
      double score = 100.0;
      final n = food.nutrition!;
      
      // If we are over limit on any macro, penalize foods high in that macro
      if (remaining.calories < 0 && (n.energyKcal ?? 0) > 200) score -= 50;
      if (remaining.protein < 0 && (n.proteinG ?? 0) > 10) score -= 40;
      if (remaining.fat < 0 && (n.fatG ?? 0) > 10) score -= 40;
      if (remaining.carbs < 0 && (n.carbsG ?? 0) > 30) score -= 40;
      
      // Goal-based priorities
      if (goal == NutritionGoal.loseWeight && (n.proteinG ?? 0) >= 15) score += 30;
      if (goal == NutritionGoal.buildMuscle && (n.proteinG ?? 0) >= 20) score += 40;

      // Blood Group Priorities (Preference-Based)
      switch (bloodGroup.type) {
        case 'O':
          // Prioritize high protein and iron (spinach/legumes)
          if ((n.proteinG ?? 0) > 15) score += 30;
          if (food.category == 'Legumes & Pulses' || food.category == 'Vegetables') score += 20;
          break;
        case 'A':
          // Emphasize vegetables and fruits
          if (food.category == 'Vegetables' || food.category == 'Fruits') score += 40;
          if (food.category == 'Legumes & Pulses') score += 20;
          break;
        case 'B':
          // Balanced - dairy and vegetables
          if (food.category == 'Dairy & Milk Products' || food.category == 'Vegetables') score += 30;
          break;
        case 'AB':
          // Mix of A and B
          if (food.category == 'Vegetables' || food.category == 'Fruits' || food.category == 'Dairy & Milk Products') score += 25;
          break;
      }
      
      return MapEntry(food, score);
    }).toList();
    
    // Sort by score and take top 5 candidates for variety
    scoredFoods.sort((a, b) => b.value.compareTo(a.value));
    candidateFoods = scoredFoods.take(5).map((e) => e.key).toList();
    candidateFoods.shuffle(Random());

    // Add 2-3 items per meal
    final itemCount = goal == NutritionGoal.buildMuscle ? 3 : 2;
    var currentMealCalories = 0.0;

    for (int i = 0; i < min(itemCount, candidateFoods.length); i++) {
      final food = candidateFoods[i];
      final nutrition = food.nutrition!;

      // Calculate servings based on target for this meal
      double servings = 1.0;
      if (nutrition.energyKcal != null && nutrition.energyKcal! > 0) {
        servings = min(
          (targetCalories - currentMealCalories) / nutrition.energyKcal!,
          2.5, // Max 2.5 servings
        );
        servings = max(servings, 0.5); // Min 0.5 servings
      }

      final item = MealItem.fromFood(food, servings);
      mealItems.add(item);
      currentMealCalories += item.calories;

      if (currentMealCalories >= targetCalories) break;
    }

    return mealItems;
  }

  double _sumCalories(List<MealItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.calories);
  }

  double _sumProtein(List<MealItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.protein);
  }

  double _sumCarbs(List<MealItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.carbs);
  }

  double _sumFat(List<MealItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.fat);
  }

  double _sumFiber(List<MealItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.fiber);
  }
}
