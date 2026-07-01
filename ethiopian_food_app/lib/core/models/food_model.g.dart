// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodModelAdapter extends TypeAdapter<FoodModel> {
  @override
  final int typeId = 5;

  @override
  FoodModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodModel(
      foodCode: fields[0] as String,
      foodName: fields[1] as String,
      foodNameAmharic: fields[2] as String?,
      category: fields[3] as String,
      keywords: (fields[4] as List?)?.cast<String>(),
      nutrition: fields[5] as NutritionModel?,
      score: fields[6] as double?,
      matchType: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.foodCode)
      ..writeByte(1)
      ..write(obj.foodName)
      ..writeByte(2)
      ..write(obj.foodNameAmharic)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.keywords)
      ..writeByte(5)
      ..write(obj.nutrition)
      ..writeByte(6)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.matchType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutritionModelAdapter extends TypeAdapter<NutritionModel> {
  @override
  final int typeId = 6;

  @override
  NutritionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionModel(
      energyKcal: fields[0] as double?,
      proteinG: fields[1] as double?,
      fatG: fields[2] as double?,
      carbsG: fields[3] as double?,
      fiberG: fields[4] as double?,
      waterG: fields[5] as double?,
      ashG: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.energyKcal)
      ..writeByte(1)
      ..write(obj.proteinG)
      ..writeByte(2)
      ..write(obj.fatG)
      ..writeByte(3)
      ..write(obj.carbsG)
      ..writeByte(4)
      ..write(obj.fiberG)
      ..writeByte(5)
      ..write(obj.waterG)
      ..writeByte(6)
      ..write(obj.ashG);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
