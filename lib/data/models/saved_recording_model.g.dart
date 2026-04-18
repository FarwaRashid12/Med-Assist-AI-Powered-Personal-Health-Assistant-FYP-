// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_recording_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedRecordingModelAdapter extends TypeAdapter<SavedRecordingModel> {
  @override
  final int typeId = 5;

  @override
  SavedRecordingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedRecordingModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      filePath: fields[3] as String,
      durationSeconds: fields[4] as int,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedRecordingModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRecordingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
