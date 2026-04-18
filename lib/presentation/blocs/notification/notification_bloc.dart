import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notification_repository.dart';
import 'notification_event_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  String? _currentUserId;

  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<AddNotification>(_onAdd);
    on<MarkNotificationAsRead>(_onMarkRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllRead);
    on<DeleteNotification>(_onDelete);
    on<ClearAllNotifications>(_onClearAll);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(NotificationLoading(notifications: state.notifications));
    try {
      final notifs = await _repository.getNotificationsForUser(event.userId);
      final unreadCount = notifs.where((n) => !n.isRead).length;
      emit(NotificationLoaded(notifs, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }

  Future<void> _onAdd(
    AddNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.addNotification(event.notification);
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notification);
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead(event.userId);
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }

  Future<void> _onDelete(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.id);
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }
  
  Future<void> _onClearAll(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.clearAllUserNotifications(event.userId);
      if (_currentUserId != null) {
        add(LoadNotifications(_currentUserId!));
      }
    } catch (e) {
      emit(NotificationError(e.toString(), notifications: state.notifications));
    }
  }
}
