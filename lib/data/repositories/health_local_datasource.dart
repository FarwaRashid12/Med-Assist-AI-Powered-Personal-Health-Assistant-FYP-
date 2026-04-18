import 'package:hive/hive.dart';
import '../models/health_vitals_model.dart';

class HealthLocalDataSource {
  static const String boxName = 'health_vitals_box';

  Future<Box<HealthVitalsModel>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<HealthVitalsModel>(boxName);
    }
    return Hive.box<HealthVitalsModel>(boxName);
  }

  Future<void> addVitals(HealthVitalsModel vitals) async {
    final box = await _getBox();
    await box.put(vitals.id, vitals);
  }

  Future<void> deleteVitals(String vitalsId) async {
    final box = await _getBox();
    await box.delete(vitalsId);
  }

  Future<List<HealthVitalsModel>> getVitalsForUser(String userId) async {
    final box = await _getBox();
    final allVitals = box.values.where((v) => v.userId == userId).toList();
    // Sort descending by timestamp (newest first)
    allVitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allVitals;
  }
}
