import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

part 'nutrition_log.g.dart';

@HiveType(typeId: 4)
class NutritionLog extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String foodCode;

  @HiveField(2)
  final String foodName;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final double servings;

  @HiveField(5)
  final double calories;

  @HiveField(6)
  final double protein;

  @HiveField(7)
  final double carbs;

  @HiveField(8)
  final double fat;

  @HiveField(9)
  final double fiber;

  @HiveField(10)
  final DateTime timestamp;

  const NutritionLog({
    required this.id,
    required this.foodCode,
    required this.foodName,
    required this.category,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.timestamp,
  });

  factory NutritionLog.fromFood({
    required FoodModel food,
    required double servings,
    required DateTime timestamp,
  }) {
    final nutrition = food.nutrition;
    return NutritionLog(
      id: '${food.foodCode}_${timestamp.millisecondsSinceEpoch}',
      foodCode: food.foodCode,
      foodName: food.foodName,
      category: food.category,
      servings: servings,
      calories: (nutrition?.energyKcal ?? 0) * servings,
      protein: (nutrition?.proteinG ?? 0) * servings,
      carbs: (nutrition?.carbsG ?? 0) * servings,
      fat: (nutrition?.fatG ?? 0) * servings,
      fiber: (nutrition?.fiberG ?? 0) * servings,
      timestamp: timestamp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        foodCode,
        foodName,
        category,
        servings,
        calories,
        protein,
        carbs,
        fat,
        fiber,
        timestamp,
      ];
}

class DailyNutritionSummary extends Equatable {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final List<NutritionLog> logs;
  final DateTime date;

  const DailyNutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.logs,
    required this.date,
  });

  factory DailyNutritionSummary.fromLogs(List<NutritionLog> logs, DateTime date) {
    return DailyNutritionSummary(
      totalCalories: logs.fold(0.0, (sum, log) => sum + log.calories),
      totalProtein: logs.fold(0.0, (sum, log) => sum + log.protein),
      totalCarbs: logs.fold(0.0, (sum, log) => sum + log.carbs),
      totalFat: logs.fold(0.0, (sum, log) => sum + log.fat),
      totalFiber: logs.fold(0.0, (sum, log) => sum + log.fiber),
      logs: logs,
      date: date,
    );
  }

  @override
  List<Object?> get props => [
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFat,
        totalFiber,
        logs,
        date,
      ];
}
