import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 10)
enum BloodGroup {
  @HiveField(0)
  aPositive,
  @HiveField(1)
  aNegative,
  @HiveField(2)
  bPositive,
  @HiveField(3)
  bNegative,
  @HiveField(4)
  abPositive,
  @HiveField(5)
  abNegative,
  @HiveField(6)
  oPositive,
  @HiveField(7)
  oNegative;

  String get displayName {
    switch (this) {
      case BloodGroup.aPositive: return 'A+';
      case BloodGroup.aNegative: return 'A-';
      case BloodGroup.bPositive: return 'B+';
      case BloodGroup.bNegative: return 'B-';
      case BloodGroup.abPositive: return 'AB+';
      case BloodGroup.abNegative: return 'AB-';
      case BloodGroup.oPositive: return 'O+';
      case BloodGroup.oNegative: return 'O-';
    }
  }

  String get type {
    switch (this) {
      case BloodGroup.aPositive:
      case BloodGroup.aNegative:
        return 'A';
      case BloodGroup.bPositive:
      case BloodGroup.bNegative:
        return 'B';
      case BloodGroup.abPositive:
      case BloodGroup.abNegative:
        return 'AB';
      case BloodGroup.oPositive:
      case BloodGroup.oNegative:
        return 'O';
    }
  }
}

@HiveType(typeId: 0)
class UserProfile extends Equatable {
  @HiveField(0)
  final int age;

  @HiveField(1)
  final Gender gender;

  @HiveField(2)
  final double height; // cm

  @HiveField(3)
  final double weight; // kg

  @HiveField(4)
  final ActivityLevel activityLevel;

  @HiveField(5)
  final NutritionGoal goal;

  @HiveField(6)
  final bool fastingMode;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final BloodGroup bloodGroup;

  const UserProfile({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
    this.fastingMode = false,
    required this.createdAt,
    required this.updatedAt,
    this.bloodGroup = BloodGroup.oPositive,
  });

  factory UserProfile.initial() {
    final now = DateTime.now();
    return UserProfile(
      age: 25,
      gender: Gender.male,
      height: 170,
      weight: 70,
      activityLevel: ActivityLevel.moderate,
      goal: NutritionGoal.maintain,
      fastingMode: false,
      bloodGroup: BloodGroup.oPositive,
      createdAt: now,
      updatedAt: now,
    );
  }

  UserProfile copyWith({
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    ActivityLevel? activityLevel,
    NutritionGoal? goal,
    bool? fastingMode,
    BloodGroup? bloodGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      fastingMode: fastingMode ?? this.fastingMode,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate BMR using Mifflin-St Jeor Equation
  double get bmr {
    if (gender == Gender.male) {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double get tdee {
    return bmr * activityLevel.multiplier;
  }

  // Calculate BMI
  double get bmi {
    return weight / ((height / 100) * (height / 100));
  }

  @override
  List<Object?> get props => [
        age,
        gender,
        height,
        weight,
        activityLevel,
        goal,
        fastingMode,
        bloodGroup,
        createdAt,
        updatedAt,
      ];
}

@HiveType(typeId: 1)
enum Gender {
  @HiveField(0)
  male,

  @HiveField(1)
  female,

  @HiveField(2)
  other;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

@HiveType(typeId: 2)
enum ActivityLevel {
  @HiveField(0)
  sedentary,

  @HiveField(1)
  light,

  @HiveField(2)
  moderate,

  @HiveField(3)
  veryActive;

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Lightly Active';
      case ActivityLevel.moderate:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.light:
        return 'Exercise 1-3 days/week';
      case ActivityLevel.moderate:
        return 'Exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Exercise 6-7 days/week';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
    }
  }
}

@HiveType(typeId: 3)
enum NutritionGoal {
  @HiveField(0)
  loseWeight,

  @HiveField(1)
  maintain,

  @HiveField(2)
  gainWeight,

  @HiveField(3)
  buildMuscle,

  @HiveField(4)
  healthyEating;

  String get displayName {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 'Lose Weight';
      case NutritionGoal.maintain:
        return 'Maintain Weight';
      case NutritionGoal.gainWeight:
        return 'Gain Weight';
      case NutritionGoal.buildMuscle:
        return 'Build Muscle';
      case NutritionGoal.healthyEating:
        return 'Healthy Eating';
    }
  }

  String get description {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 'Calorie deficit for weight loss';
      case NutritionGoal.maintain:
        return 'Maintain current weight';
      case NutritionGoal.gainWeight:
        return 'Calorie surplus for weight gain';
      case NutritionGoal.buildMuscle:
        return 'High protein for muscle building';
      case NutritionGoal.healthyEating:
        return 'Balanced nutrition';
    }
  }

  int getCalorieAdjustment(double tdee) {
    switch (this) {
      case NutritionGoal.loseWeight:
        return -500;
      case NutritionGoal.maintain:
        return 0;
      case NutritionGoal.gainWeight:
        return 300;
      case NutritionGoal.buildMuscle:
        return 300;
      case NutritionGoal.healthyEating:
        return 0;
    }
  }

  double getProteinMultiplier() {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 1.6; // Higher protein for weight loss
      case NutritionGoal.maintain:
        return 1.2;
      case NutritionGoal.gainWeight:
        return 1.4;
      case NutritionGoal.buildMuscle:
        return 2.0; // High protein for muscle building
      case NutritionGoal.healthyEating:
        return 1.2;
    }
  }
}
