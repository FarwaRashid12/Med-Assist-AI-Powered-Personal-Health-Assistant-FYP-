import 'package:medassist/data/models/reminder_models.dart';
import 'package:medassist/data/models/saved_prescription_model.dart';

/// Parses a [SavedPrescriptionModel] and generates a list of [ReminderSlot]s,
/// each covering a contiguous date range per time-of-day bucket.
class ReminderGenerator {
  static List<ReminderSlot> generate(
    SavedPrescriptionModel prescription,
    DateTime startDate,
  ) {
    // Normalise to midnight
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final count = prescription.medicineNames.length;

    final slotBuckets = <SlotType, List<_MedDuration>>{
      SlotType.morning: [],
      SlotType.afternoon: [],
      SlotType.evening: [],
    };

    for (int i = 0; i < count; i++) {
      final name =
          i < prescription.medicineNames.length ? prescription.medicineNames[i] : '';
      if (name.trim().isEmpty) continue;

      final dosage =
          i < prescription.medicineDosages.length ? prescription.medicineDosages[i] : '';
      final frequency =
          i < prescription.medicineFrequencies.length ? prescription.medicineFrequencies[i] : '';
      final whenToTake =
          i < prescription.medicineTimings.length ? prescription.medicineTimings[i] : '';
      final durationStr =
          i < prescription.medicineDurations.length ? prescription.medicineDurations[i] : '';

      final days = _parseDuration(durationStr);
      final endDate = start.add(Duration(days: days - 1));
      final slots = _parseFrequency(frequency);
      final entry = ReminderMedicineEntry(
          name: name, dosage: dosage, whenToTake: whenToTake);

      for (final slot in slots) {
        slotBuckets[slot]!.add(_MedDuration(entry: entry, endDate: endDate));
      }
    }

    const defaultTimes = {
      SlotType.morning: '08:00 AM',
      SlotType.afternoon: '02:00 PM',
      SlotType.evening: '08:00 PM',
    };

    final result = <ReminderSlot>[];
    for (final slotType in SlotType.values) {
      final meds = slotBuckets[slotType]!;
      if (meds.isEmpty) continue;
      final periods = _createPeriods(start, meds);
      if (periods.isEmpty) continue;
      result.add(ReminderSlot(
        id: '${slotType.index}_${prescription.id}',
        slotType: slotType,
        scheduledTime: defaultTimes[slotType]!,
        periods: periods,
      ));
    }
    return result;
  }

  // ── Duration parser ──────────────────────────────────────────────────────

  static int _parseDuration(String raw) {
    if (raw.trim().isEmpty) return 7;
    final s = raw.toLowerCase();

    final d = RegExp(r'(\d+)\s*day').firstMatch(s);
    if (d != null) return int.parse(d.group(1)!).clamp(1, 365);

    final w = RegExp(r'(\d+)\s*week').firstMatch(s);
    if (w != null) return (int.parse(w.group(1)!) * 7).clamp(1, 365);

    final m = RegExp(r'(\d+)\s*month').firstMatch(s);
    if (m != null) return (int.parse(m.group(1)!) * 30).clamp(1, 365);

    // Fallback: bare number → treat as days
    final n = RegExp(r'^\s*(\d+)\s*$').firstMatch(s);
    if (n != null) return int.parse(n.group(1)!).clamp(1, 365);

    return 7;
  }

  // ── Frequency → slot set ─────────────────────────────────────────────────

  static Set<SlotType> _parseFrequency(String freq) {
    if (freq.trim().isEmpty) return {SlotType.morning};
    final s = freq.toLowerCase();

    // SOS / prn → no scheduled slots
    if (s.startsWith('sos') || s.contains('when needed') || s.contains('prn')) {
      return {};
    }

    // X+Y+Z pattern (e.g. 1+1+1, 1+0+1)
    final m3 = RegExp(r'^(\d+)\+(\d+)\+(\d+)').firstMatch(freq);
    if (m3 != null) {
      final slots = <SlotType>{};
      if (int.parse(m3.group(1)!) > 0) slots.add(SlotType.morning);
      if (int.parse(m3.group(2)!) > 0) slots.add(SlotType.afternoon);
      if (int.parse(m3.group(3)!) > 0) slots.add(SlotType.evening);
      return slots.isEmpty ? {SlotType.morning} : slots;
    }

    // X+Y pattern (e.g. 1+1 → morning + evening)
    final m2 = RegExp(r'^(\d+)\+(\d+)').firstMatch(freq);
    if (m2 != null) {
      final slots = <SlotType>{};
      if (int.parse(m2.group(1)!) > 0) slots.add(SlotType.morning);
      if (int.parse(m2.group(2)!) > 0) slots.add(SlotType.evening);
      return slots.isEmpty ? {SlotType.morning} : slots;
    }

    // Named shortcuts
    if (s.contains('tds') || s.contains('three times')) {
      return {SlotType.morning, SlotType.afternoon, SlotType.evening};
    }
    if (s.contains('bd') || s.contains('twice') ||
        s.contains('morning + evening') || s.contains('morning and evening')) {
      return {SlotType.morning, SlotType.evening};
    }
    if (s.contains('bedtime') || s.contains('night only') ||
        s.contains('evening only') || s.contains('0+0+1')) {
      return {SlotType.evening};
    }
    if (s.contains('afternoon only')) return {SlotType.afternoon};
    if (s.contains('od') || s.contains('once daily') || s.contains('once a day')) {
      return {SlotType.morning};
    }

    return {SlotType.morning};
  }

  // ── Period splitter ──────────────────────────────────────────────────────
  //
  // Given N medicines with (possibly different) endDates, produce the minimal
  // set of contiguous ReminderPeriods.
  //
  // Example:
  //   MedA ends day+2, MedB ends day+4, MedC ends day+13
  //   → Period1 [day0..day2]:  A+B+C
  //   → Period2 [day3..day4]:  B+C
  //   → Period3 [day5..day13]: C

  static List<ReminderPeriod> _createPeriods(
    DateTime startDate,
    List<_MedDuration> meds,
  ) {
    final uniqueEnds = meds.map((m) => m.endDate).toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    final periods = <ReminderPeriod>[];
    DateTime periodStart = startDate;

    for (final endDate in uniqueEnds) {
      final active = meds.where((m) => !m.endDate.isBefore(endDate)).toList();
      if (active.isNotEmpty) {
        periods.add(ReminderPeriod(
          startDate: periodStart,
          endDate: endDate,
          medicines: active.map((m) => m.entry).toList(),
        ));
      }
      periodStart = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));
    }
    return periods;
  }
}

// Internal helper
class _MedDuration {
  final ReminderMedicineEntry entry;
  final DateTime endDate;
  _MedDuration({required this.entry, required this.endDate});
}
