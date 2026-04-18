class ConsultationModel {
  final String transcript;
  final List<String> medicines;
  final List<String> lifestyle;

  ConsultationModel({
    required this.transcript,
    required this.medicines,
    required this.lifestyle,
  });

  factory ConsultationModel.empty() {
    return ConsultationModel(
      transcript: '',
      medicines: [],
      lifestyle: [],
    );
  }

  factory ConsultationModel.fromJson(Map<String, dynamic> json, String rawTranscript) {
    return ConsultationModel(
      transcript: rawTranscript,
      medicines: List<String>.from(json['medicines'] ?? []),
      lifestyle: List<String>.from(json['lifestyle'] ?? []),
    );
  }
}
