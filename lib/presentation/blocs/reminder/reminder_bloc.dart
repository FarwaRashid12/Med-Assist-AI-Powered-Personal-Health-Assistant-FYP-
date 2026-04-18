import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medassist/core/services/notification_service.dart';
import 'package:medassist/data/repositories/reminder_repository.dart';
import 'reminder_event_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository _repository;

  ReminderBloc(this._repository) : super(const ReminderInitial()) {
    on<LoadReminders>(_onLoad);
    on<GenerateReminders>(_onGenerate);
    on<UpdateReminderSlots>(_onUpdateSlots);
    on<DeleteReminder>(_onDelete);
  }

  // ── Helper: reschedule all notifications for a user ──────────────────────

  Future<void> _rescheduleNotifications(String userId) async {
    try {
      final models = await _repository.loadAll(userId);
      final decoded = models.map((m) => _repository.decodeSlots(m)).toList();
      await NotificationService.rescheduleAll(models, decoded);
    } catch (_) {
      // Non-fatal — notifications may not be available in all environments
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      LoadReminders event, Emitter<ReminderState> emit) async {
    emit(const ReminderLoading());
    try {
      final reminders = await _repository.loadAll(event.userId);
      emit(RemindersLoaded(reminders));
    } catch (e) {
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onGenerate(
      GenerateReminders event, Emitter<ReminderState> emit) async {
    emit(const ReminderLoading());
    try {
      final reminder =
          await _repository.generate(event.prescription, event.startDate);
      final all = await _repository.loadAll(event.prescription.userId);
      emit(ReminderGenerated(reminder: reminder, allReminders: all));

      // Schedule actual notifications for every reminder
      await _rescheduleNotifications(event.prescription.userId);
    } catch (e) {
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onUpdateSlots(
      UpdateReminderSlots event, Emitter<ReminderState> emit) async {
    try {
      await _repository.updateSlots(event.model, event.slots);
      final all = await _repository.loadAll(event.model.userId);
      emit(RemindersLoaded(all));

      // Reschedule so new times take effect
      await _rescheduleNotifications(event.model.userId);
    } catch (e) {
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteReminder event, Emitter<ReminderState> emit) async {
    emit(const ReminderLoading());
    try {
      await _repository.delete(event.reminderId);
      final all = await _repository.loadAll(event.userId);
      emit(RemindersLoaded(all));

      // Cancel + re-schedule remaining reminders
      await _rescheduleNotifications(event.userId);
    } catch (e) {
      emit(ReminderError(e.toString()));
    }
  }
}
