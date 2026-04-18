class PrescriptionMedicine {
  String name;
  String dosage;
  String frequency;
  String durationDays; // e.g. "7 days", "2 weeks"
  String whenToTake;
  int confidence;

  PrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    required this.whenToTake,
    required this.confidence,
  });

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      durationDays: json['duration_days'] ?? '',
      whenToTake: json['when_to_take'] ?? '',
      confidence: json['confidence'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration_days': durationDays,
        'when_to_take': whenToTake,
        'confidence': confidence,
      };
}

class PrescriptionModel {
  final String clinicName;
  final String doctorName;
  final String notes;
  final Map<String, String>? extractedVitals;
  final List<PrescriptionMedicine> medicines;

  PrescriptionModel({
    required this.clinicName,
    required this.doctorName,
    required this.notes,
    this.extractedVitals,
    required this.medicines,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? vitalsMap;
    if (json['vitals'] != null) {
      vitalsMap = {};
      (json['vitals'] as Map).forEach((key, value) {
        vitalsMap![key.toString()] = value.toString();
      });
    }

    return PrescriptionModel(
      clinicName: json['clinic_name'] ?? 'Not mentioned',
      doctorName: json['doctor_name'] ?? 'Not mentioned',
      notes: json['notes'] ?? '',
      extractedVitals: vitalsMap,
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
