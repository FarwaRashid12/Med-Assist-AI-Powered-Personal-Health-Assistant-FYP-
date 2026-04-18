import 'package:hive/hive.dart';

part 'health_vitals_model.g.dart';

@HiveType(typeId: 1)
class HealthVitalsModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final int systolic;

  @HiveField(3)
  final int diastolic;

  @HiveField(4)
  final double bloodSugar;

  @HiveField(5)
  final int heartRate;

  @HiveField(6)
  final DateTime timestamp;

  HealthVitalsModel({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.bloodSugar,
    required this.heartRate,
    required this.timestamp,
  });
}
