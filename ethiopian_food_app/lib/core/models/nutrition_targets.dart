import 'package:equatable/equatable.dart';

class NutritionTargets extends Equatable {
  final double calories;
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final double fiber; // g

  const NutritionTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory NutritionTargets.fromProfile(
    double tdee,
    double weight,
    int calorieAdjustment,
    double proteinMultiplier,
  ) {
    final targetCalories = tdee + calorieAdjustment;

    // Protein: based on weight and goal
    final protein = weight * proteinMultiplier;

    // Fat: 25-30% of calories
    final fatCalories = targetCalories * 0.275;
    final fat = fatCalories / 9; // 9 calories per gram of fat

    // Carbs: remaining calories
    final proteinCalories = protein * 4;
    final carbCalories = targetCalories - proteinCalories - fatCalories;
    final carbs = carbCalories / 4; // 4 calories per gram of carbs

    // Fiber: 14g per 1000 calories
    final fiber = (targetCalories / 1000) * 14;

    return NutritionTargets(
      calories: targetCalories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
    );
  }

  @override
  List<Object?> get props => [calories, protein, carbs, fat, fiber];
}
