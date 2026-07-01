import 'package:equatable/equatable.dart';
import 'package:ethiopian_food_app/core/models/food_model.dart';

class Recommendation extends Equatable {
  final String reason;
  final RecommendationType type;
  final List<FoodModel> foods;
  final String? description;

  const Recommendation({
    required this.reason,
    required this.type,
    required this.foods,
    this.description,
  });

  @override
  List<Object?> get props => [reason, type, foods, description];
}

enum RecommendationType {
  highProtein,
  highFiber,
  lowCalorie,
  balanced,
  bloodGroup;

  String get displayName {
    switch (this) {
      case RecommendationType.highProtein:
        return 'High Protein';
      case RecommendationType.highFiber:
        return 'High Fiber';
      case RecommendationType.lowCalorie:
        return 'Low Calorie';
      case RecommendationType.balanced:
        return 'Balanced';
      case RecommendationType.bloodGroup:
        return 'Blood Group Recommendation';
    }
  }

  String get icon {
    switch (this) {
      case RecommendationType.highProtein:
        return '💪';
      case RecommendationType.highFiber:
        return '🌾';
      case RecommendationType.lowCalorie:
        return '🥗';
      case RecommendationType.balanced:
        return '⚖️';
      case RecommendationType.bloodGroup:
        return '🩸';
    }
  }
}
