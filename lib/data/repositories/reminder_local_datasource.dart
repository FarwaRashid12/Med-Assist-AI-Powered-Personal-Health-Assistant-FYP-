import 'package:hive/hive.dart';
import '../models/prescription_reminder_model.dart';

class ReminderLocalDataSource {
  static const String _boxName = 'prescription_reminders';
  Box<PrescriptionReminderModel>? _box;

  Future<Box<PrescriptionReminderModel>> _getBox() async {
    _box ??= await Hive.openBox<PrescriptionReminderModel>(_boxName);
    return _box!;
  }

  Future<void> save(PrescriptionReminderModel model) async {
    final box = await _getBox();
    await box.put(model.id, model);
  }

  Future<List<PrescriptionReminderModel>> getAllForUser(String userId) async {
    final box = await _getBox();
    return box.values
        .where((r) => r.userId == userId)
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  Future<PrescriptionReminderModel?> getByPrescriptionId(
      String prescriptionId) async {
    final box = await _getBox();
    for (final r in box.values) {
      if (r.prescriptionId == prescriptionId) return r;
    }
    return null;
  }

  Future<PrescriptionReminderModel?> getById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
