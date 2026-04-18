import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medassist/core/constants/app_colors.dart';
import 'package:medassist/core/router/app_router.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';
import 'package:medassist/data/models/saved_prescription_model.dart';
import 'package:medassist/presentation/blocs/auth/auth_bloc.dart';
import 'package:medassist/presentation/blocs/auth/auth_event_state.dart';
import 'package:medassist/presentation/blocs/prescription/prescription_bloc.dart';
import 'package:medassist/presentation/blocs/prescription/prescription_event_state.dart';
import 'package:medassist/presentation/blocs/reminder/reminder_event_state.dart';
import 'package:medassist/presentation/blocs/reminder/reminder_bloc.dart';
import 'package:medassist/presentation/blocs/notification/notification_bloc.dart';
import 'package:medassist/presentation/blocs/notification/notification_event_state.dart';
import 'package:medassist/data/models/notification_model.dart';
import 'package:uuid/uuid.dart';
import 'package:medassist/presentation/blocs/family/active_profile_cubit.dart';
import 'package:medassist/core/services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthBloc>().state;
    String? baseId;
    String? baseName;
    if (auth is AuthAuthenticated) {
      baseId = auth.user.id;
      baseName = auth.user.fullName;
    } else if (auth is AuthRegisterSuccess) {
      baseId = auth.user.id;
      baseName = auth.user.fullName;
    }
    
    if (baseId != null && baseName != null) {
      final newId = context.watch<ActiveProfileCubit>().getCompositeUserId(baseId, baseName);
      if (_userId != newId) {
        _userId = newId;
        context.read<PrescriptionBloc>().add(LoadSavedPrescriptions(_userId!));
        context.read<ReminderBloc>().add(LoadReminders(_userId!));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _generateReminders(SavedPrescriptionModel p,
      {bool isRegenerate = false}) async {
    if (isRegenerate) {
      final confirmed = await _confirmRegenerate(p);
      if (!confirmed || !mounted) return;
    }

    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      helpText: 'When should reminders start?',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      context
          .read<ReminderBloc>()
          .add(GenerateReminders(prescription: p, startDate: picked));
    }
  }

  Future<bool> _confirmRegenerate(SavedPrescriptionModel p) async {
    final title =
        p.doctorName != 'Not mentioned' ? p.doctorName : p.clinicName;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Regenerate Reminders?',
                style:
                    GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            content: Text(
              'This will replace your existing reminders for $title. '
              'Any edits you made to the schedule will be lost.',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Regenerate',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Future<void> _showDeletePrescriptionDialog(SavedPrescriptionModel p, PrescriptionReminderModel? r) async {
    final title = p.doctorName != 'Not mentioned' ? p.doctorName : p.clinicName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Prescription?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$title"?\n\n'
          'This will permanently remove the saved prescription${r != null ? ' AND its active reminders' : ''}.',
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

    if (confirmed == true && mounted && _userId != null) {
      if (r != null) {
        context.read<ReminderBloc>().add(DeleteReminder(reminderId: r.id, userId: _userId!));
      }
      context.read<PrescriptionBloc>().add(DeleteSavedPrescription(p.id, _userId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state is ReminderGenerated) {
          if (mounted && _userId != null) {
            context.read<ReminderBloc>().add(LoadReminders(_userId!));
            
            final notification = NotificationModel(
              id: const Uuid().v4(),
              userId: _userId!,
              title: 'Reminders Active',
              body: 'Your medication reminders have been successfully set.',
              type: 'Reminder',
              timestamp: DateTime.now(),
            );
            context.read<NotificationBloc>().add(AddNotification(notification));

            // NEW: Real push confirmation for diagnostics
            NotificationService.showInstantNotification(
              title: notification.title,
              body: notification.body,
            );

            // NEW: Beautiful Confirmation Dialog
            _showSuccessDialog();
          }
        } else if (state is ReminderError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Reminders',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, reminderState) {
            final isGenerating = reminderState is ReminderLoading;
            final List<PrescriptionReminderModel> reminders =
                reminderState is RemindersLoaded
                    ? reminderState.reminders
                    : reminderState is ReminderGenerated
                        ? reminderState.allReminders
                        : [];

            return BlocBuilder<PrescriptionBloc, PrescriptionState>(
              builder: (context, prescriptionState) {
                if (prescriptionState is PrescriptionError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error: ${prescriptionState.message}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (prescriptionState is! SavedPrescriptionsLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final prescriptions = prescriptionState.prescriptions;
                if (prescriptions.isEmpty) return _buildEmptyState();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(children: [
                        if (reminders.isNotEmpty)
                          _buildStatsHeader(reminders, prescriptions),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(children: [
                            const Icon(Icons.receipt_long_rounded,
                                size: 18,
                                color: AppColors.textPrimary),
                            const SizedBox(width: 8),
                            Text('Your Prescriptions',
                                style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const Spacer(),
                            Text('${prescriptions.length} saved',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ]),
                        ),
                        _buildTestAlarmChip(),
                      ]),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Make Alarms Reliable',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'For the voice and full-screen alert to work, please ensure "Display over other apps" is allowed for MedAssist in your phone settings.',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: prescriptions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final p = prescriptions[index];
                          PrescriptionReminderModel? existing;
                          for (final r in reminders) {
                            if (r.prescriptionId == p.id) {
                              existing = r;
                              break;
                            }
                          }
                          return _buildPrescriptionCard(
                              p, existing, isGenerating);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildStatsHeader(List<PrescriptionReminderModel> reminders,
      List<SavedPrescriptionModel> prescriptions) {
    final totalSlots = reminders.fold<int>(
        0, (sum, r) => sum + r.reminderSlotsJson.length);
    final pending = prescriptions.length - reminders.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
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
        _statCol('${reminders.length}', 'Active\nPrescriptions'),
        _vDivider(),
        _statCol('$totalSlots', 'Total Daily\nSlots'),
        _vDivider(),
        _statCol('${pending < 0 ? 0 : pending}', 'Awaiting\nSetup'),
      ]),
    );
  }

  Widget _statCol(String v, String label) => Expanded(
        child: Column(children: [
          Text(v,
              style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.3)),
        ]),
      );

  Widget _vDivider() => Container(
      width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3));

  Widget _buildPrescriptionCard(SavedPrescriptionModel p,
      PrescriptionReminderModel? reminder, bool isGenerating) {
    final hasReminder = reminder != null;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final title =
        p.doctorName != 'Not mentioned' ? p.doctorName : p.clinicName;
    final subtitle =
        p.doctorName != 'Not mentioned' ? p.clinicName : '';
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasReminder
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.5),
        ),
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
          // ── Header ──
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasReminder
                    ? AppColors.primarySurface
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial,
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: hasReminder
                            ? AppColors.primary
                            : AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${subtitle.isNotEmpty ? '$subtitle · ' : ''}'
                    'Saved ${dateFormat.format(p.savedAt)} · '
                    '${p.medicineCount} med${p.medicineCount != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasReminder
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasReminder ? '✅ Active' : '⏳ Pending',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasReminder
                        ? AppColors.success
                        : AppColors.warning),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'delete') {
                  _showDeletePrescriptionDialog(p, reminder);
                }
              },
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Text('Delete Prescription', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ]),

          // ── Slot preview ──
          if (hasReminder && reminder.reminderSlotsJson.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: reminder.reminderSlotsJson.map((j) {
                try {
                  final slot = ReminderSlot.fromJson(
                      jsonDecode(j) as Map<String, dynamic>);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(slot.slotEmoji,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          '${slot.slotName} · ${slot.scheduledTime}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Action buttons ──
          if (hasReminder)
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(
                      AppRouter.reminderDetail,
                      extra: reminder),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('View Reminders',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () =>
                    _generateReminders(p, isRegenerate: true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
            ])
          else
            GestureDetector(
              onTap: isGenerating
                  ? null
                  : () => _generateReminders(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isGenerating
                      ? AppColors.surfaceVariant
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGenerating)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary))
                    else
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isGenerating
                          ? 'Generating...'
                          : '✦ Generate Reminders',
                      style: GoogleFonts.inter(
                          color: isGenerating
                              ? AppColors.textHint
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_off_rounded,
                size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text('No Prescriptions Yet',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Scan a prescription first, then come back here to '
              'generate your medication reminders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => context.go(AppRouter.scanner),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.document_scanner_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Scan a Prescription',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
            const SizedBox(height: 20),
            Text('Reminders Set!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'Your medication schedule has been intelligently generated and your voice-enabled alarms are active.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Perfect', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestAlarmChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          NotificationService.showTestNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test alarm scheduled for 5 seconds... Lock your phone!')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bug_report_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'TEST INTELLIGENT ALARM (5 SEC)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
