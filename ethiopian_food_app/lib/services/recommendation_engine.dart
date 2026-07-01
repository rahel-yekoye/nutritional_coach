import 'package:ethiopian_food_app/core/models/recommendation.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/nutrition_targets.dart';
import 'package:ethiopian_food_app/core/models/nutrition_log.dart';

class RecommendationEngine {
  String getDailyNutrientFocus(BloodGroup bloodGroup) {
    switch (bloodGroup.type) {
      case 'O':
        return 'Iron & Protein';
      case 'A':
        return 'Fiber & Plant Protein';
      case 'B':
        return 'Balanced Macronutrients';
      case 'AB':
        return 'Variety & Micronutrient Balance';
      default:
        return 'Balanced Nutrition';
    }
  }

  String getBloodGroupAdvice(BloodGroup bloodGroup) {
    switch (bloodGroup.type) {
      case 'O':
        return 'Prioritize iron-rich foods and lean protein sources like fish, eggs, legumes, and spinach.';
      case 'A':
        return 'Emphasize vegetables, legumes, fruits, and plant-based proteins.';
      case 'B':
        return 'Focus on a balanced mixed diet including dairy, vegetables, and lean proteins.';
      case 'AB':
        return 'Incorporate a combination of Type A and Type B recommendations for a diverse nutrient profile.';
      default:
        return 'Maintain a balanced diet with a variety of whole foods.';
    }
  }

  List<Recommendation> generateRecommendations({
    required List<FoodModel> allFoods,
    required UserProfile profile,
    required NutritionTargets targets,
    required DailyNutritionSummary todaySummary,
  }) {
    final recommendations = <Recommendation>[];

    // Filter foods based on fasting mode
    final availableFoods =
        profile.fastingMode ? _filterFastingFoods(allFoods) : allFoods;

    // Calculate progress
    final calorieProgress = todaySummary.totalCalories / targets.calories;
    final proteinProgress = todaySummary.totalProtein / targets.protein;
    final fiberProgress = todaySummary.totalFiber / targets.fiber;

    // 1. Blood Group Specific Recommendation (Dynamic based on intake)
    final bloodGroupRec = _generateBloodGroupRecommendation(
      availableFoods,
      profile.bloodGroup,
      todaySummary,
      targets,
    );
    if (bloodGroupRec != null) {
      recommendations.add(bloodGroupRec);
    }

    // 2. High Protein Recommendation (if protein < 50%)
    if (proteinProgress < 0.5) {
      final highProteinFoods = _getHighProteinFoods(availableFoods, limit: 5);
      if (highProteinFoods.isNotEmpty) {
        recommendations.add(Recommendation(
          reason: 'Boost Your Protein',
          type: RecommendationType.highProtein,
          foods: highProteinFoods,
          description:
              'You need ${(targets.protein - todaySummary.totalProtein).toStringAsFixed(1)}g more protein today',
        ));
      }
    }

    // 3. High Fiber Recommendation (if fiber < 50%)
    if (fiberProgress < 0.5) {
      final highFiberFoods = _getHighFiberFoods(availableFoods, limit: 5);
      if (highFiberFoods.isNotEmpty) {
        recommendations.add(Recommendation(
          reason: 'Add More Fiber',
          type: RecommendationType.highFiber,
          foods: highFiberFoods,
          description:
              'You need ${(targets.fiber - todaySummary.totalFiber).toStringAsFixed(1)}g more fiber today',
        ));
      }
    }

    // 4. Low Calorie Recommendation (if calories exceeded or close)
    if (calorieProgress > 0.8) {
      final lowCalorieFoods = _getLowCalorieFoods(availableFoods, limit: 5);
      if (lowCalorieFoods.isNotEmpty) {
        recommendations.add(Recommendation(
          reason: 'Low Calorie Options',
          type: RecommendationType.lowCalorie,
          foods: lowCalorieFoods,
          description:
              'You have ${(targets.calories - todaySummary.totalCalories).toStringAsFixed(0)} calories remaining',
        ));
      }
    }

    // 5. Balanced Recommendation
    final balancedFoods = _getBalancedFoods(availableFoods, limit: 5);
    if (balancedFoods.isNotEmpty) {
      recommendations.add(Recommendation(
        reason: 'Balanced Options',
        type: RecommendationType.balanced,
        foods: balancedFoods,
        description: 'Well-rounded foods for your goals',
      ));
    }

    return recommendations;
  }

  Recommendation? _generateBloodGroupRecommendation(
    List<FoodModel> foods,
    BloodGroup bloodGroup,
    DailyNutritionSummary summary,
    NutritionTargets targets,
  ) {
    final remainingProtein = targets.protein - summary.totalProtein;
    final remainingFiber = targets.fiber - summary.totalFiber;

    switch (bloodGroup.type) {
      case 'O':
        if (remainingProtein > 20) {
          final proteinFoods = _getHighProteinFoods(foods, limit: 3);
          return Recommendation(
            reason: 'Preference-Based Recommendation',
            type: RecommendationType.bloodGroup,
            foods: proteinFoods,
            description:
                'Protein intake is below target. Consider adding fish, eggs, lentils, or other protein-rich foods (Type O Preference).',
          );
        }
        break;
      case 'A':
        if (remainingFiber > 5) {
          final fiberFoods = _getHighFiberFoods(foods, limit: 3);
          return Recommendation(
            reason: 'Preference-Based Recommendation',
            type: RecommendationType.bloodGroup,
            foods: fiberFoods,
            description:
                'Fiber intake is below target. Consider vegetables, fruits, and legumes (Type A Preference).',
          );
        }
        break;
      case 'B':
        final balancedFoods = _getBalancedFoods(foods, limit: 3);
        return Recommendation(
          reason: 'Preference-Based Recommendation',
          type: RecommendationType.bloodGroup,
          foods: balancedFoods,
          description:
              'Focus on variety. Your blood type thrives on a balanced mix of dairy, vegetables, and lean proteins.',
        );
      case 'AB':
        final varietyFoods = _getBalancedFoods(foods, limit: 3);
        return Recommendation(
          reason: 'Preference-Based Recommendation',
          type: RecommendationType.bloodGroup,
          foods: varietyFoods,
          description:
              'Maintain variety with a combination of plant proteins and light dairy options.',
        );
    }
    return null;
  }

  List<FoodModel> _filterFastingFoods(List<FoodModel> foods) {
    // Ethiopian Orthodox Fasting excludes:
    // - Meat & Poultry
    // - Fish & Seafood
    // - Dairy & Milk Products
    // - Eggs
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

  List<FoodModel> _getHighProteinFoods(List<FoodModel> foods, {int limit = 5}) {
    final proteinFoods = foods
        .where((food) =>
            food.nutrition?.proteinG != null &&
            food.nutrition!.proteinG! > 10)
        .toList();

    proteinFoods.sort((a, b) =>
        (b.nutrition?.proteinG ?? 0).compareTo(a.nutrition?.proteinG ?? 0));

    return proteinFoods.take(limit).toList();
  }

  List<FoodModel> _getHighFiberFoods(List<FoodModel> foods, {int limit = 5}) {
    final fiberFoods = foods
        .where((food) =>
            food.nutrition?.fiberG != null && food.nutrition!.fiberG! > 5)
        .toList();

    fiberFoods.sort((a, b) =>
        (b.nutrition?.fiberG ?? 0).compareTo(a.nutrition?.fiberG ?? 0));

    return fiberFoods.take(limit).toList();
  }

  List<FoodModel> _getLowCalorieFoods(List<FoodModel> foods, {int limit = 5}) {
    final lowCalFoods = foods
        .where((food) =>
            food.nutrition?.energyKcal != null &&
            food.nutrition!.energyKcal! < 100)
        .toList();

    lowCalFoods.sort((a, b) =>
        (a.nutrition?.energyKcal ?? 0).compareTo(b.nutrition?.energyKcal ?? 0));

    return lowCalFoods.take(limit).toList();
  }

  List<FoodModel> _getBalancedFoods(List<FoodModel> foods, {int limit = 5}) {
    // Balanced: reasonable calories, protein, fiber
    final balancedFoods = foods.where((food) {
      final nutrition = food.nutrition;
      if (nutrition == null) return false;

      final calories = nutrition.energyKcal ?? 0;
      final protein = nutrition.proteinG ?? 0;
      final fiber = nutrition.fiberG ?? 0;

      return calories > 50 &&
          calories < 300 &&
          protein > 5 &&
          fiber > 2;
    }).toList();

    // Shuffle for variety
    balancedFoods.shuffle();

    return balancedFoods.take(limit).toList();
  }
}
