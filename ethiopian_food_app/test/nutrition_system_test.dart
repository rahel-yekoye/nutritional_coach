import 'package:flutter_test/flutter_test.dart';
import 'package:ethiopian_food_app/core/models/unified_nutrition_state.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';
import 'package:ethiopian_food_app/services/meal_planner.dart';

void main() {
  group('MealPlannerService Adaptive Logic Tests', () {
    late MealPlannerService service;
    late List<FoodModel> mockFoods;

    setUp(() {
      service = MealPlannerService();
      mockFoods = [
        const FoodModel(
          foodCode: '1',
          foodName: 'High Fat Meat',
          category: 'Meat & Poultry',
          nutrition: NutritionModel(energyKcal: 500, fatG: 40, proteinG: 20, carbsG: 0),
        ),
        const FoodModel(
          foodCode: '2',
          foodName: 'High Protein Legume',
          category: 'Legumes & Pulses',
          nutrition: NutritionModel(energyKcal: 200, fatG: 2, proteinG: 25, carbsG: 30),
        ),
        const FoodModel(
          foodCode: '3',
          foodName: 'High Carb Grain',
          category: 'Cereals & Grains',
          nutrition: NutritionModel(energyKcal: 350, fatG: 1, proteinG: 5, carbsG: 70),
        ),
        const FoodModel(
          foodCode: '4',
          foodName: 'Veggies 1',
          category: 'Vegetables',
          nutrition: NutritionModel(energyKcal: 50, fatG: 0, proteinG: 2, carbsG: 10),
        ),
        const FoodModel(
          foodCode: '5',
          foodName: 'Veggies 2',
          category: 'Vegetables',
          nutrition: NutritionModel(energyKcal: 60, fatG: 0, proteinG: 3, carbsG: 12),
        ),
        const FoodModel(
          foodCode: '6',
          foodName: 'Fruit 1',
          category: 'Fruits',
          nutrition: NutritionModel(energyKcal: 80, fatG: 0, proteinG: 1, carbsG: 20),
        ),
      ];
    });

    test('Should penalize high-fat foods when fat limit is exceeded', () {
      final state = const UnifiedNutritionState(
        dailyIntake: NutritionValues(fat: 60), // Over limit
        dailyTargets: NutritionValues(fat: 50),
        remaining: NutritionValues(fat: -10),
        goal: NutritionGoal.maintain,
        bloodGroup: BloodGroup.oPositive,
        isFasting: false,
      );

      final plan = service.generateMealPlan(allFoods: mockFoods, state: state);
      
      // Check that "High Fat Meat" is NOT in the plan because of the penalty
      final allMealItems = [...plan.breakfast, ...plan.lunch, ...plan.dinner];
      final containsHighFat = allMealItems.any((item) => item.food.foodName == 'High Fat Meat');
      
      expect(containsHighFat, isFalse, reason: 'High fat food should be penalized when fat limit is exceeded');
    });

    test('Should prioritize high-protein foods for muscle building goal', () {
      final state = const UnifiedNutritionState(
        dailyIntake: NutritionValues(),
        dailyTargets: NutritionValues(calories: 2500, protein: 150),
        remaining: NutritionValues(calories: 2500, protein: 150),
        goal: NutritionGoal.buildMuscle,
        bloodGroup: BloodGroup.oPositive,
        isFasting: false,
      );

      final plan = service.generateMealPlan(allFoods: mockFoods, state: state);
      
      // For muscle building, "High Protein Legume" (high protein ratio) should be preferred
      final allMealItems = [...plan.breakfast, ...plan.lunch, ...plan.dinner];
      expect(allMealItems.any((item) => item.food.foodName == 'High Protein Legume'), isTrue);
    });
  });
}
