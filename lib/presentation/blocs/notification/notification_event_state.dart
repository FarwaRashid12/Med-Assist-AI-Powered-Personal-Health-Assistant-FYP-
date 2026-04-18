import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;
  const LoadNotifications(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddNotification extends NotificationEvent {
  final NotificationModel notification;
  const AddNotification(this.notification);

  @override
  List<Object> get props => [notification];
}

class MarkNotificationAsRead extends NotificationEvent {
  final NotificationModel notification;
  const MarkNotificationAsRead(this.notification);

  @override
  List<Object> get props => [notification];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;
  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object> get props => [userId];
}

class DeleteNotification extends NotificationEvent {
  final String id;
  const DeleteNotification(this.id);

  @override
  List<Object> get props => [id];
}

class ClearAllNotifications extends NotificationEvent {
  final String userId;
  const ClearAllNotifications(this.userId);

  @override
  List<Object> get props => [userId];
}

abstract class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  const NotificationState({this.notifications = const []});

  @override
  List<Object?> get props => [notifications];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial() : super(notifications: const []);
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({super.notifications});
}

class NotificationLoaded extends NotificationState {
  final int unreadCount;
  const NotificationLoaded(List<NotificationModel> notifications, {required this.unreadCount}) 
      : super(notifications: notifications);

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message, {super.notifications});

  @override
  List<Object?> get props => [message, notifications];
}
