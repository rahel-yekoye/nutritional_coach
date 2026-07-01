import 'package:equatable/equatable.dart';

enum MacroStatus {
  overLimit,
  onTrack,
  underTarget;

  String get displayName {
    switch (this) {
      case MacroStatus.overLimit:
        return 'Over Limit';
      case MacroStatus.onTrack:
        return 'On Track';
      case MacroStatus.underTarget:
        return 'Under Target';
    }
  }
}

class MacroAnalysis extends Equatable {
  final double target;
  final double actual;
  final MacroStatus status;

  const MacroAnalysis({
    required this.target,
    required this.actual,
    required this.status,
  });

  @override
  List<Object?> get props => [target, actual, status];
}

class NutritionAnalysis extends Equatable {
  final MacroAnalysis calories;
  final MacroAnalysis protein;
  final MacroAnalysis fat;
  final MacroAnalysis carbs;
  final String overallStatus;
  final int score; // 0-100 for visual indicator

  const NutritionAnalysis({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.overallStatus,
    required this.score,
  });

  @override
  List<Object?> get props => [calories, protein, fat, carbs, overallStatus, score];
}
