import '../models/notification_model.dart';
import 'notification_local_datasource.dart';

class NotificationRepository {
  final NotificationLocalDataSource _localDataSource;

  NotificationRepository(this._localDataSource);

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    return await _localDataSource.getNotificationsForUser(userId);
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _localDataSource.addNotification(notification);
  }

  Future<void> markAsRead(NotificationModel notification) async {
    final updated = notification.copyWith(isRead: true);
    await _localDataSource.updateNotification(updated);
  }

  Future<void> markAllAsRead(String userId) async {
    await _localDataSource.markAllAsRead(userId);
  }

  Future<void> deleteNotification(String id) async {
    await _localDataSource.deleteNotification(id);
  }
  
  Future<void> clearAllUserNotifications(String userId) async {
    await _localDataSource.clearAllUserNotifications(userId);
  }
}
