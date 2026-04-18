import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:medassist/core/constants/app_colors.dart';
import 'package:medassist/core/router/app_router.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';

/// Shows the focused slot details as a bottom sheet.
/// Called when user taps a notification.
class SlotFocusBottomSheet extends StatelessWidget {
  final PrescriptionReminderModel model;
  final String slotId;

  const SlotFocusBottomSheet({
    super.key,
    required this.model,
    required this.slotId,
  });

  static Future<void> show(
    BuildContext context, {
    required PrescriptionReminderModel model,
    required String slotId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SlotFocusBottomSheet(model: model, slotId: slotId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Find the matching slot
    ReminderSlot? slot;
    for (final j in model.reminderSlotsJson) {
      try {
        final s =
            ReminderSlot.fromJson(jsonDecode(j) as Map<String, dynamic>);
        if (s.id == slotId) {
          slot = s;
          break;
        }
      } catch (_) {}
    }

    // Fallback: pick first slot if ID not matched
    if (slot == null && model.reminderSlotsJson.isNotEmpty) {
      try {
        slot = ReminderSlot.fromJson(
            jsonDecode(model.reminderSlotsJson.first) as Map<String, dynamic>);
      } catch (_) {}
    }

    // Today's active medicines from the first matching period
    final today = DateTime.now();
    List<ReminderMedicineEntry> todayMeds = [];
    if (slot != null) {
      for (final period in slot.periods) {
        if (!today.isBefore(period.startDate) &&
            !today.isAfter(period.endDate)) {
          todayMeds = period.medicines;
          break;
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // ── Header ──────────────────────────────────────────
                    if (slot != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Text(slot.slotEmoji,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${slot.slotName} Medication',
                                  style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${slot.scheduledTime}  •  ${model.prescriptionTitle}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),

                    const SizedBox(height: 20),

                    // ── Medicines ────────────────────────────────────────
                    if (todayMeds.isEmpty)
                      _empty()
                    else ...[
                      Row(children: [
                        const Icon(Icons.medication_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Take Now — ${todayMeds.length} medicine${todayMeds.length != 1 ? 's' : ''}',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      ...todayMeds.map((med) => _medCard(med)),
                    ],

                    const SizedBox(height: 24),

                    // ── Action buttons ───────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRouter.reminderDetail,
                            extra: model);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('View Full Schedule',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 6),
                            Text('Dismiss',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _medCard(ReminderMedicineEntry med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (med.dosage.isNotEmpty)
                      _chip(med.dosage, AppColors.primary),
                    if (med.whenToTake.isNotEmpty)
                      _chip(med.whenToTake, AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No medicines active for today in this slot.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
}
