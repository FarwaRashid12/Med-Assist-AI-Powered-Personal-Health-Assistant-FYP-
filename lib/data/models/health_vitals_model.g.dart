// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_vitals_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthVitalsModelAdapter extends TypeAdapter<HealthVitalsModel> {
  @override
  final int typeId = 1;

  @override
  HealthVitalsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthVitalsModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      systolic: fields[2] as int,
      diastolic: fields[3] as int,
      bloodSugar: fields[4] as double,
      heartRate: fields[5] as int,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HealthVitalsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.systolic)
      ..writeByte(3)
      ..write(obj.diastolic)
      ..writeByte(4)
      ..write(obj.bloodSugar)
      ..writeByte(5)
      ..write(obj.heartRate)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthVitalsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
