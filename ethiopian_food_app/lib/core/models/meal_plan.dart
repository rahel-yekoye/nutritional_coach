import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

part 'meal_plan.g.dart';

@HiveType(typeId: 7)
class MealPlan extends Equatable {
  @HiveField(0)
  final List<MealItem> breakfast;

  @HiveField(1)
  final List<MealItem> lunch;

  @HiveField(2)
  final List<MealItem> dinner;

  @HiveField(3)
  final double totalCalories;

  @HiveField(4)
  final double totalProtein;

  @HiveField(5)
  final double totalCarbs;

  @HiveField(6)
  final double totalFat;

  @HiveField(7)
  final double totalFiber;

  @HiveField(8)
  final DateTime generatedAt;

  const MealPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        breakfast,
        lunch,
        dinner,
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFat,
        totalFiber,
        generatedAt,
      ];
}

@HiveType(typeId: 8)
class MealItem extends Equatable {
  @HiveField(0)
  final FoodModel food;

  @HiveField(1)
  final double servings;

  @HiveField(2)
  final double calories;

  @HiveField(3)
  final double protein;

  @HiveField(4)
  final double carbs;

  @HiveField(5)
  final double fat;

  @HiveField(6)
  final double fiber;

  const MealItem({
    required this.food,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory MealItem.fromFood(FoodModel food, double servings) {
    final nutrition = food.nutrition;
    return MealItem(
      food: food,
      servings: servings,
      calories: (nutrition?.energyKcal ?? 0) * servings,
      protein: (nutrition?.proteinG ?? 0) * servings,
      carbs: (nutrition?.carbsG ?? 0) * servings,
      fat: (nutrition?.fatG ?? 0) * servings,
      fiber: (nutrition?.fiberG ?? 0) * servings,
    );
  }

  @override
  List<Object?> get props => [food, servings, calories, protein, carbs, fat, fiber];
}

@HiveType(typeId: 9)
enum MealType {
  @HiveField(0)
  breakfast,

  @HiveField(1)
  lunch,

  @HiveField(2)
  dinner;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
    }
  }
}
