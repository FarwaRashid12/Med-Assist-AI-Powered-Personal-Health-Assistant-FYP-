import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:medassist/core/services/reminder_generator.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';
import 'package:medassist/data/models/saved_prescription_model.dart';
import 'package:medassist/data/repositories/reminder_local_datasource.dart';

class ReminderRepository {
  final ReminderLocalDataSource _ds;
  ReminderRepository(this._ds);

  /// Generates (or regenerates) a reminder schedule for [prescription].
  /// Any previously saved reminder for that prescription is replaced.
  Future<PrescriptionReminderModel> generate(
    SavedPrescriptionModel prescription,
    DateTime startDate,
  ) async {
    // Replace existing reminder if one exists
    final existing = await _ds.getByPrescriptionId(prescription.id);
    if (existing != null) await _ds.delete(existing.id);

    final slots = ReminderGenerator.generate(prescription, startDate);
    final slotsJson = slots.map((s) => jsonEncode(s.toJson())).toList();

    final title = prescription.doctorName != 'Not mentioned'
        ? prescription.doctorName
        : prescription.clinicName;

    final model = PrescriptionReminderModel(
      id: const Uuid().v4(),
      userId: prescription.userId,
      prescriptionId: prescription.id,
      prescriptionTitle: title,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      generatedAt: DateTime.now(),
      reminderSlotsJson: slotsJson,
    );

    await _ds.save(model);
    return model;
  }

  Future<List<PrescriptionReminderModel>> loadAll(String userId) =>
      _ds.getAllForUser(userId);

  Future<PrescriptionReminderModel?> getById(String id) => _ds.getById(id);

  Future<PrescriptionReminderModel?> getByPrescriptionId(String id) =>
      _ds.getByPrescriptionId(id);

  Future<void> updateSlots(
      PrescriptionReminderModel model, List<ReminderSlot> slots) async {
    model.reminderSlotsJson = slots.map((s) => jsonEncode(s.toJson())).toList();
    await _ds.save(model);
  }

  Future<void> delete(String id) => _ds.delete(id);

  List<ReminderSlot> decodeSlots(PrescriptionReminderModel model) =>
      model.reminderSlotsJson
          .map((j) =>
              ReminderSlot.fromJson(jsonDecode(j) as Map<String, dynamic>))
          .toList();
}
