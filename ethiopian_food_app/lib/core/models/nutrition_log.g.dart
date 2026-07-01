// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionLogAdapter extends TypeAdapter<NutritionLog> {
  @override
  final int typeId = 4;

  @override
  NutritionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionLog(
      id: fields[0] as String,
      foodCode: fields[1] as String,
      foodName: fields[2] as String,
      category: fields[3] as String,
      servings: fields[4] as double,
      calories: fields[5] as double,
      protein: fields[6] as double,
      carbs: fields[7] as double,
      fat: fields[8] as double,
      fiber: fields[9] as double,
      timestamp: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.foodCode)
      ..writeByte(2)
      ..write(obj.foodName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.servings)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.carbs)
      ..writeByte(8)
      ..write(obj.fat)
      ..writeByte(9)
      ..write(obj.fiber)
      ..writeByte(10)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
