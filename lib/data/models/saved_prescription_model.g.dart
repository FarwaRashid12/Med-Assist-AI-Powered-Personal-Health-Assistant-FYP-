// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_prescription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedPrescriptionModelAdapter
    extends TypeAdapter<SavedPrescriptionModel> {
  @override
  final int typeId = 2;

  @override
  SavedPrescriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedPrescriptionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      clinicName: fields[2] as String,
      doctorName: fields[3] as String,
      medicineNames: fields[4] == null ? [] : (fields[4] as List).cast<String>(),
      medicineDosages:
          fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      medicineFrequencies:
          fields[6] == null ? [] : (fields[6] as List).cast<String>(),
      medicineTimings:
          fields[7] == null ? [] : (fields[7] as List).cast<String>(),
      medicineDurations:
          fields[9] == null ? [] : (fields[9] as List).cast<String>(),
      notes: fields[10] == null ? '' : fields[10] as String,
      vitals:
          fields[11] == null ? {} : (fields[11] as Map).cast<String, String>(),
      savedAt: fields[8] as DateTime,
      imagePath: fields[12] as String?,
      audioPath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedPrescriptionModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.clinicName)
      ..writeByte(3)
      ..write(obj.doctorName)
      ..writeByte(4)
      ..write(obj.medicineNames)
      ..writeByte(5)
      ..write(obj.medicineDosages)
      ..writeByte(6)
      ..write(obj.medicineFrequencies)
      ..writeByte(7)
      ..write(obj.medicineTimings)
      ..writeByte(9)
      ..write(obj.medicineDurations)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.vitals)
      ..writeByte(8)
      ..write(obj.savedAt)
      ..writeByte(12)
      ..write(obj.imagePath)
      ..writeByte(13)
      ..write(obj.audioPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPrescriptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
