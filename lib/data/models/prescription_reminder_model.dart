import 'package:hive/hive.dart';

part 'prescription_reminder_model.g.dart';

/// Persisted reminder schedule for a single saved prescription.
/// Each [reminderSlotsJson] entry is a JSON-encoded [ReminderSlot].
@HiveType(typeId: 3)
class PrescriptionReminderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String prescriptionId;

  @HiveField(3)
  final String prescriptionTitle;

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  final DateTime generatedAt;

  @HiveField(6)
  List<String> reminderSlotsJson;

  PrescriptionReminderModel({
    required this.id,
    required this.userId,
    required this.prescriptionId,
    required this.prescriptionTitle,
    required this.startDate,
    required this.generatedAt,
    required this.reminderSlotsJson,
  });
}
