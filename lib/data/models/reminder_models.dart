// Pure Dart models for reminder data structures.
// These are NOT stored in Hive directly — they are serialised as JSON strings
// inside PrescriptionReminderModel.reminderSlotsJson.

enum SlotType { morning, afternoon, evening }

// ---------------------------------------------------------------------------
// ReminderMedicineEntry
// ---------------------------------------------------------------------------
class ReminderMedicineEntry {
  String name;
  String dosage;
  String whenToTake;

  ReminderMedicineEntry({
    required this.name,
    required this.dosage,
    required this.whenToTake,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'whenToTake': whenToTake,
      };

  factory ReminderMedicineEntry.fromJson(Map<String, dynamic> json) =>
      ReminderMedicineEntry(
        name: json['name'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        whenToTake: json['whenToTake'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// ReminderPeriod — one contiguous date range within a slot
// ---------------------------------------------------------------------------
class ReminderPeriod {
  DateTime startDate;
  DateTime endDate;
  List<ReminderMedicineEntry> medicines;

  ReminderPeriod({
    required this.startDate,
    required this.endDate,
    required this.medicines,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'medicines': medicines.map((m) => m.toJson()).toList(),
      };

  factory ReminderPeriod.fromJson(Map<String, dynamic> json) => ReminderPeriod(
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        medicines: (json['medicines'] as List)
            .map((m) => ReminderMedicineEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// ReminderSlot — one time-of-day bucket (Morning / Afternoon / Evening)
// ---------------------------------------------------------------------------
class ReminderSlot {
  final String id;
  final SlotType slotType;
  String scheduledTime; // e.g. "08:00 AM"
  List<ReminderPeriod> periods;
  String notes;

  ReminderSlot({
    required this.id,
    required this.slotType,
    required this.scheduledTime,
    required this.periods,
    this.notes = '',
  });

  String get slotName {
    switch (slotType) {
      case SlotType.morning:
        return 'Morning';
      case SlotType.afternoon:
        return 'Afternoon';
      case SlotType.evening:
        return 'Evening';
    }
  }

  String get slotEmoji {
    switch (slotType) {
      case SlotType.morning:
        return '☀️';
      case SlotType.afternoon:
        return '🌤️';
      case SlotType.evening:
        return '🌙';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slotType': slotType.index,
        'scheduledTime': scheduledTime,
        'periods': periods.map((p) => p.toJson()).toList(),
        'notes': notes,
      };

  factory ReminderSlot.fromJson(Map<String, dynamic> json) => ReminderSlot(
        id: json['id'] as String? ?? '',
        slotType: SlotType.values[(json['slotType'] as int?) ?? 0],
        scheduledTime: json['scheduledTime'] as String? ?? '08:00 AM',
        periods: (json['periods'] as List)
            .map((p) => ReminderPeriod.fromJson(p as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String? ?? '',
      );
}
