// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      age: fields[0] as int,
      gender: fields[1] as Gender,
      height: fields[2] as double,
      weight: fields[3] as double,
      activityLevel: fields[4] as ActivityLevel,
      goal: fields[5] as NutritionGoal,
      fastingMode: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      bloodGroup: fields[9] as BloodGroup,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.age)
      ..writeByte(1)
      ..write(obj.gender)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.activityLevel)
      ..writeByte(5)
      ..write(obj.goal)
      ..writeByte(6)
      ..write(obj.fastingMode)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.bloodGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BloodGroupAdapter extends TypeAdapter<BloodGroup> {
  @override
  final int typeId = 10;

  @override
  BloodGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BloodGroup.aPositive;
      case 1:
        return BloodGroup.aNegative;
      case 2:
        return BloodGroup.bPositive;
      case 3:
        return BloodGroup.bNegative;
      case 4:
        return BloodGroup.abPositive;
      case 5:
        return BloodGroup.abNegative;
      case 6:
        return BloodGroup.oPositive;
      case 7:
        return BloodGroup.oNegative;
      default:
        return BloodGroup.aPositive;
    }
  }

  @override
  void write(BinaryWriter writer, BloodGroup obj) {
    switch (obj) {
      case BloodGroup.aPositive:
        writer.writeByte(0);
        break;
      case BloodGroup.aNegative:
        writer.writeByte(1);
        break;
      case BloodGroup.bPositive:
        writer.writeByte(2);
        break;
      case BloodGroup.bNegative:
        writer.writeByte(3);
        break;
      case BloodGroup.abPositive:
        writer.writeByte(4);
        break;
      case BloodGroup.abNegative:
        writer.writeByte(5);
        break;
      case BloodGroup.oPositive:
        writer.writeByte(6);
        break;
      case BloodGroup.oNegative:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloodGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = 1;

  @override
  Gender read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Gender.male;
      case 1:
        return Gender.female;
      case 2:
        return Gender.other;
      default:
        return Gender.male;
    }
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    switch (obj) {
      case Gender.male:
        writer.writeByte(0);
        break;
      case Gender.female:
        writer.writeByte(1);
        break;
      case Gender.other:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityLevelAdapter extends TypeAdapter<ActivityLevel> {
  @override
  final int typeId = 2;

  @override
  ActivityLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityLevel.sedentary;
      case 1:
        return ActivityLevel.light;
      case 2:
        return ActivityLevel.moderate;
      case 3:
        return ActivityLevel.veryActive;
      default:
        return ActivityLevel.sedentary;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityLevel obj) {
    switch (obj) {
      case ActivityLevel.sedentary:
        writer.writeByte(0);
        break;
      case ActivityLevel.light:
        writer.writeByte(1);
        break;
      case ActivityLevel.moderate:
        writer.writeByte(2);
        break;
      case ActivityLevel.veryActive:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutritionGoalAdapter extends TypeAdapter<NutritionGoal> {
  @override
  final int typeId = 3;

  @override
  NutritionGoal read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NutritionGoal.loseWeight;
      case 1:
        return NutritionGoal.maintain;
      case 2:
        return NutritionGoal.gainWeight;
      case 3:
        return NutritionGoal.buildMuscle;
      case 4:
        return NutritionGoal.healthyEating;
      default:
        return NutritionGoal.loseWeight;
    }
  }

  @override
  void write(BinaryWriter writer, NutritionGoal obj) {
    switch (obj) {
      case NutritionGoal.loseWeight:
        writer.writeByte(0);
        break;
      case NutritionGoal.maintain:
        writer.writeByte(1);
        break;
      case NutritionGoal.gainWeight:
        writer.writeByte(2);
        break;
      case NutritionGoal.buildMuscle:
        writer.writeByte(3);
        break;
      case NutritionGoal.healthyEating:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
