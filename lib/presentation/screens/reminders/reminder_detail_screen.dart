import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medassist/core/constants/app_colors.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';
import 'package:medassist/presentation/blocs/reminder/reminder_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medassist/presentation/blocs/reminder/reminder_event_state.dart';

class ReminderDetailScreen extends StatefulWidget {
  final PrescriptionReminderModel model;
  const ReminderDetailScreen({super.key, required this.model});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  List<ReminderSlot> _slots = [];
  final Map<int, TextEditingController> _notesControllers = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _decodeSlots();
  }

  void _decodeSlots() {
    _slots = widget.model.reminderSlotsJson.map((j) {
      return ReminderSlot.fromJson(jsonDecode(j) as Map<String, dynamic>);
    }).toList();
    for (int i = 0; i < _slots.length; i++) {
      _notesControllers[i] =
          TextEditingController(text: _slots[i].notes);
    }
  }

  @override
  void dispose() {
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _editTime(int index) async {
    final slot = _slots[index];
    TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
    try {
      // Parse "08:00 AM" or "02:00 PM"
      final isPM = slot.scheduledTime.contains('PM');
      final timePart =
          slot.scheduledTime.replaceAll(' AM', '').replaceAll(' PM', '');
      final parts = timePart.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      initialTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final picked =
        await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null && mounted) {
      setState(() {
        _slots[index].scheduledTime = picked.format(context);
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() {
    // Flush notes from controllers
    for (int i = 0; i < _slots.length; i++) {
      _slots[i].notes = _notesControllers[i]?.text ?? '';
    }
    context.read<ReminderBloc>().add(
          UpdateReminderSlots(
              model: widget.model, slots: List.from(_slots)),
        );
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Reminders saved!'),
      backgroundColor: AppColors.success,
    ));
  }

  Future<void> _showDeleteReminderDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Reminders?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete all generated reminders for this prescription?\n\n'
          'The saved prescription itself will NOT be deleted.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ReminderBloc>().add(DeleteReminder(reminderId: widget.model.id, userId: widget.model.userId));
      context.pop(); // Go back to previous screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reminders deleted successfully.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.model.prescriptionTitle,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saveChanges,
                child: Text('Save',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 15)),
              ),
            ),
          if (!_hasChanges)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _showDeleteReminderDialog,
            ),
        ],
      ),
      body: _slots.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              children: [
                const SizedBox(height: 4),
                _buildHeaderCard(),
                const SizedBox(height: 20),
                ..._slots.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSlotCard(e.key, e.value),
                      ),
                    ),
              ],
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final fmt = DateFormat('MMM dd, yyyy');
    final totalMeds = _slots.isEmpty
        ? 0
        : _slots
            .expand((s) => s.periods.isNotEmpty ? s.periods.first.medicines : [])
            .map((m) => m.name)
            .toSet()
            .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.calendar_month_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reminder Schedule',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Starting ${fmt.format(widget.model.startDate)}'
                ' · ${_slots.length} slot${_slots.length != 1 ? 's' : ''}'
                ' · $totalMeds medicine${totalMeds != 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Slot card ─────────────────────────────────────────────────────────────

  Widget _buildSlotCard(int index, ReminderSlot slot) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Slot header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text(slot.slotEmoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(slot.slotName,
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              // Tappable time chip → time picker
              GestureDetector(
                onTap: () => _editTime(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryLight
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(slot.scheduledTime,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded,
                          size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // ── Periods ──
          ...slot.periods.asMap().entries.map((e) => Column(children: [
                if (e.key > 0)
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1)),
                _buildPeriodSection(e.value),
              ])),

          // ── Notes ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Notes',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesControllers[index],
                  onChanged: (_) =>
                      setState(() => _hasChanges = true),
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Add a note for this time slot (optional)…',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textHint, fontSize: 13),
                    contentPadding: const EdgeInsets.all(10),
                    fillColor: AppColors.surfaceVariant,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Period section ────────────────────────────────────────────────────────

  Widget _buildPeriodSection(ReminderPeriod period) {
    final fmt = DateFormat('MMM dd');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(
                  '${fmt.format(period.startDate)} – ${fmt.format(period.endDate)}'
                  '  •  ${period.durationDays} day${period.durationDays != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Medicine list
          ...period.medicines.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (med.dosage.isNotEmpty)
                                _badge(med.dosage,
                                    AppColors.primarySurface,
                                    AppColors.primary),
                              if (med.whenToTake.isNotEmpty)
                                _badge(med.whenToTake,
                                    AppColors.surfaceVariant,
                                    AppColors.textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off_rounded,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No Reminder Slots',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Could not generate slots.\nCheck that medicines have valid frequencies.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
