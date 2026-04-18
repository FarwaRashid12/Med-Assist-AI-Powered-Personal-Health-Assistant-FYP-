import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';
import 'package:medassist/data/models/saved_prescription_model.dart';

// ── Events ────────────────────────────────────────────────────────────────

abstract class ReminderEvent {
  const ReminderEvent();
}

class LoadReminders extends ReminderEvent {
  final String userId;
  const LoadReminders(this.userId);
}

class GenerateReminders extends ReminderEvent {
  final SavedPrescriptionModel prescription;
  final DateTime startDate;
  const GenerateReminders({required this.prescription, required this.startDate});
}

class UpdateReminderSlots extends ReminderEvent {
  final PrescriptionReminderModel model;
  final List<ReminderSlot> slots;
  const UpdateReminderSlots({required this.model, required this.slots});
}

class DeleteReminder extends ReminderEvent {
  final String reminderId;
  final String userId;
  const DeleteReminder({required this.reminderId, required this.userId});
}

// ── States ────────────────────────────────────────────────────────────────

abstract class ReminderState {
  const ReminderState();
}

class ReminderInitial extends ReminderState {
  const ReminderInitial();
}

class ReminderLoading extends ReminderState {
  const ReminderLoading();
}

class RemindersLoaded extends ReminderState {
  final List<PrescriptionReminderModel> reminders;
  const RemindersLoaded(this.reminders);
}

/// Emitted after a successful [GenerateReminders] event.
/// The UI listens for this to navigate to the detail screen.
class ReminderGenerated extends ReminderState {
  final PrescriptionReminderModel reminder;
  final List<PrescriptionReminderModel> allReminders;
  const ReminderGenerated({required this.reminder, required this.allReminders});
}

class ReminderError extends ReminderState {
  final String message;
  const ReminderError(this.message);
}
