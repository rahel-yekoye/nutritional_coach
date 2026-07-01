import 'package:equatable/equatable.dart';
import 'package:ethiopian_food_app/core/models/user_profile.dart';

class NutritionValues extends Equatable {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  const NutritionValues({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
  });

  NutritionValues operator -(NutritionValues other) {
    return NutritionValues(
      calories: calories - other.calories,
      protein: protein - other.protein,
      fat: fat - other.fat,
      carbs: carbs - other.carbs,
      fiber: fiber - other.fiber,
    );
  }

  @override
  List<Object?> get props => [calories, protein, fat, carbs, fiber];
}

class UnifiedNutritionState extends Equatable {
  final NutritionValues dailyIntake;
  final NutritionValues dailyTargets;
  final NutritionValues remaining;
  final NutritionGoal goal;
  final BloodGroup bloodGroup;
  final bool isFasting;

  const UnifiedNutritionState({
    required this.dailyIntake,
    required this.dailyTargets,
    required this.remaining,
    required this.goal,
    required this.bloodGroup,
    required this.isFasting,
  });

  @override
  List<Object?> get props => [
        dailyIntake,
        dailyTargets,
        remaining,
        goal,
        bloodGroup,
        isFasting,
      ];
}
