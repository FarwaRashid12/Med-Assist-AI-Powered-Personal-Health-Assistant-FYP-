import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_model.dart';

class NotificationLocalDataSource {
  static const String boxName = 'notifications_box';

  Future<Box<NotificationModel>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<NotificationModel>(boxName);
    }
    return Hive.box<NotificationModel>(boxName);
  }

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    final box = await _getBox();
    final notifs = box.values.where((n) => n.userId == userId).toList();
    // Sort newest first
    notifs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifs;
  }

  Future<void> addNotification(NotificationModel notification) async {
    final box = await _getBox();
    await box.put(notification.id, notification);
  }

  Future<void> updateNotification(NotificationModel notification) async {
    final box = await _getBox();
    await box.put(notification.id, notification);
  }

  Future<void> markAllAsRead(String userId) async {
    final box = await _getBox();
    final userNotifs = box.values.where((n) => n.userId == userId && !n.isRead);
    for (var notif in userNotifs) {
      notif.isRead = true;
      await notif.save();
    }
  }

  Future<void> deleteNotification(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
  
  Future<void> clearAllUserNotifications(String userId) async {
    final box = await _getBox();
    final keysToDelete = box.keys.where((k) {
      final notif = box.get(k);
      return notif != null && notif.userId == userId;
    }).toList();
    await box.deleteAll(keysToDelete);
  }
}
