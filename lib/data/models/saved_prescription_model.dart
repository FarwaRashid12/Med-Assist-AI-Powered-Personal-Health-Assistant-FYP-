import 'package:hive/hive.dart';

part 'saved_prescription_model.g.dart';

@HiveType(typeId: 2)
class SavedPrescriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String clinicName;

  @HiveField(3)
  final String doctorName;

  @HiveField(4, defaultValue: [])
  final List<String> medicineNames;

  @HiveField(5, defaultValue: [])
  final List<String> medicineDosages;

  @HiveField(6, defaultValue: [])
  final List<String> medicineFrequencies;

  @HiveField(7, defaultValue: [])
  final List<String> medicineTimings;

  @HiveField(9, defaultValue: [])
  final List<String> medicineDurations;

  @HiveField(10, defaultValue: '')
  final String notes;

  @HiveField(11, defaultValue: {})
  final Map<String, String> vitals;

  @HiveField(8)
  final DateTime savedAt;

  @HiveField(12)
  final String? imagePath;

  @HiveField(13)
  final String? audioPath;

  SavedPrescriptionModel({
    required this.id,
    required this.userId,
    required this.clinicName,
    required this.doctorName,
    required this.medicineNames,
    required this.medicineDosages,
    required this.medicineFrequencies,
    required this.medicineTimings,
    required this.medicineDurations,
    required this.notes,
    required this.vitals,
    required this.savedAt,
    this.imagePath,
    this.audioPath,
  });

  factory SavedPrescriptionModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SavedPrescriptionModel(
      id: id,
      userId: json['userId'] ?? '',
      clinicName: json['clinicName'] ?? '',
      doctorName: json['doctorName'] ?? '',
      medicineNames: List<String>.from(json['medicineNames'] ?? []),
      medicineDosages: List<String>.from(json['medicineDosages'] ?? []),
      medicineFrequencies: List<String>.from(json['medicineFrequencies'] ?? []),
      medicineTimings: List<String>.from(json['medicineTimings'] ?? []),
      medicineDurations: List<String>.from(json['medicineDurations'] ?? []),
      notes: json['notes'] ?? '',
      vitals: Map<String, String>.from(json['vitals'] ?? {}),
      savedAt: json['savedAt'] != null
          ? (json['savedAt'] as dynamic).toDate()
          : DateTime.now(),
      imagePath: json['imagePath'],
      audioPath: json['audioPath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'clinicName': clinicName,
      'doctorName': doctorName,
      'medicineNames': medicineNames,
      'medicineDosages': medicineDosages,
      'medicineFrequencies': medicineFrequencies,
      'medicineTimings': medicineTimings,
      'medicineDurations': medicineDurations,
      'notes': notes,
      'vitals': vitals,
      'savedAt': savedAt,
      'imagePath': imagePath,
      'audioPath': audioPath,
    };
  }

  /// Helper to get medicine count
  int get medicineCount => medicineNames.length;

  /// Helper to get a summary string of all medicines
  String get medicineSummary => medicineNames.join(', ');
}
