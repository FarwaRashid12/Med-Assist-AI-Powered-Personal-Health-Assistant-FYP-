// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilyProfileModelAdapter extends TypeAdapter<FamilyProfileModel> {
  @override
  final int typeId = 4;

  @override
  FamilyProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyProfileModel(
      id: fields[0] as String,
      parentUserId: fields[1] as String,
      name: fields[2] as String,
      relation: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyProfileModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentUserId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.relation)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
