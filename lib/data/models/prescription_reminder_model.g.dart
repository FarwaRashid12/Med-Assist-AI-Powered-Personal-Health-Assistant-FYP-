// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescription_reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrescriptionReminderModelAdapter
    extends TypeAdapter<PrescriptionReminderModel> {
  @override
  final int typeId = 3;

  @override
  PrescriptionReminderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrescriptionReminderModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      prescriptionId: fields[2] as String,
      prescriptionTitle: fields[3] as String,
      startDate: fields[4] as DateTime,
      generatedAt: fields[5] as DateTime,
      reminderSlotsJson: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PrescriptionReminderModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.prescriptionId)
      ..writeByte(3)
      ..write(obj.prescriptionTitle)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.generatedAt)
      ..writeByte(6)
      ..write(obj.reminderSlotsJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrescriptionReminderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
