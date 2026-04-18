import 'package:hive/hive.dart';
import '../models/saved_recording_model.dart';
import 'dart:io';

class RecordingRepository {
  static const String boxName = 'saved_recordings_box';

  Future<Box<SavedRecordingModel>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<SavedRecordingModel>(boxName);
    }
    return Hive.box<SavedRecordingModel>(boxName);
  }

  Future<void> saveRecording(SavedRecordingModel recording) async {
    final box = await _getBox();
    await box.put(recording.id, recording);
  }

  Future<List<SavedRecordingModel>> getRecordings(String userId) async {
    final box = await _getBox();
    final all = box.values.where((r) => r.userId == userId).toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first
    return all;
  }

  Future<void> deleteRecording(String id) async {
    final box = await _getBox();
    final recording = box.get(id);
    if (recording != null) {
      // Also delete the physical local audio file
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await box.delete(id);
  }
}
