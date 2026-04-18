import 'package:hive/hive.dart';
import '../models/saved_prescription_model.dart';

class PrescriptionLocalDataSource {
  static const String boxName = 'saved_prescriptions_box';

  Future<Box<SavedPrescriptionModel>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<SavedPrescriptionModel>(boxName);
    }
    return Hive.box<SavedPrescriptionModel>(boxName);
  }

  Future<void> savePrescription(SavedPrescriptionModel prescription) async {
    final box = await _getBox();
    await box.put(prescription.id, prescription);
  }

  Future<List<SavedPrescriptionModel>> getPrescriptionsForUser(String userId) async {
    final box = await _getBox();
    final all = box.values.where((p) => p.userId == userId).toList();
    all.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return all;
  }

  Future<void> deletePrescription(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
