import '../models/health_vitals_model.dart';
import 'health_local_datasource.dart';

class HealthRepository {
  final HealthLocalDataSource _dataSource;

  HealthRepository(this._dataSource);

  Future<void> addVitals(HealthVitalsModel vitals) async {
    await _dataSource.addVitals(vitals);
  }

  Future<void> deleteVitals(String vitalsId) async {
    await _dataSource.deleteVitals(vitalsId);
  }

  Future<List<HealthVitalsModel>> getVitalsHistory(String userId) async {
    return await _dataSource.getVitalsForUser(userId);
  }
}
