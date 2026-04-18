import 'package:hive/hive.dart';

part 'saved_recording_model.g.dart';

@HiveType(typeId: 5)
class SavedRecordingModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String filePath;

  @HiveField(4)
  final int durationSeconds;

  @HiveField(5)
  final DateTime timestamp;

  SavedRecordingModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.timestamp,
  });
}
