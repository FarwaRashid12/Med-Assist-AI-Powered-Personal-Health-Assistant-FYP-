import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/health_vitals_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/health/health_bloc.dart';
import '../../blocs/health/health_event_state.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/reminder/reminder_bloc.dart';
import '../../blocs/reminder/reminder_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event_state.dart';
import '../../../data/models/notification_model.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/health/add_vitals_bottom_sheet.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    String? baseId;
    String? baseName;
    if (authState is AuthAuthenticated) {
      baseId = authState.user.id;
      baseName = authState.user.fullName;
    } else if (authState is AuthRegisterSuccess) {
      baseId = authState.user.id;
      baseName = authState.user.fullName;
    }

    if (baseId != null && baseName != null) {
      final newId = context.watch<ActiveProfileCubit>().getCompositeUserId(baseId, baseName);
      
      // Load ALL relevant data when the ID changes or screen is initial
      final healthState = context.read<HealthBloc>().state;
      if (_userId != newId || healthState is HealthInitial) {
        _userId = newId;
        
        // 1. Load Vitals Log
        context.read<HealthBloc>().add(LoadHealthVitals(_userId!));
        
        // 2. Load Prescription Hub (Fixes Rx lag)
        context.read<PrescriptionBloc>().add(LoadSavedPrescriptions(_userId!));
        
        // 3. Load Reminders Count (Fixes Plans lag)
        context.read<ReminderBloc>().add(LoadReminders(_userId!));
      }
    }
  }

  void _showAddVitalsSheet(BuildContext context) async {
    if (_userId == null) return;

    final newVitals = await showModalBottomSheet<HealthVitalsModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVitalsBottomSheet(userId: _userId!),
    );

    if (newVitals != null && mounted) {
      context.read<HealthBloc>().add(AddHealthVitals(newVitals));
      
      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: _userId!,
        title: 'New Vitals Logged',
        body: 'Your reading was successfully saved to health analytics.',
        type: 'Health',
        timestamp: DateTime.now(),
      );
      context.read<NotificationBloc>().add(AddNotification(notification));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals logged successfully'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = context.watch<HealthBloc>().state;
    final prescriptionState = context.watch<PrescriptionBloc>().state;
    final reminderState = context.watch<ReminderBloc>().state;

    int activePrescriptions = 0;
    if (prescriptionState is SavedPrescriptionsLoaded) {
      activePrescriptions = prescriptionState.prescriptions.length;
    }

    int totalSchedules = 0;
    if (reminderState is RemindersLoaded) {
      totalSchedules = reminderState.reminders.length;
    }

    int avgSystolic = 0;
    int avgDiastolic = 0;
    int bpCount = 0;
    
    int totalVitalsLogged = 0;
    int latestSystolic = 0;
    int latestDiastolic = 0;
    double latestSugar = 0;
    int latestHR = 0;

    if (healthState is HealthLoaded) {
      totalVitalsLogged = healthState.vitals.length;
      for (var v in healthState.vitals) {
        if (v.systolic > 0 && v.diastolic > 0) {
          avgSystolic += v.systolic;
          avgDiastolic += v.diastolic;
          bpCount++;
        }
      }
      if (bpCount > 0) {
        avgSystolic = (avgSystolic / bpCount).round();
        avgDiastolic = (avgDiastolic / bpCount).round();
      }

      // Latest reading — find the most recent entry that has each specific metric.
      // Vitals are already sorted newest-first by the datasource.
      if (healthState.vitals.isNotEmpty) {
        final latestBPEntry    = healthState.vitals.firstWhere((v) => v.systolic > 0 && v.diastolic > 0, orElse: () => healthState.vitals.first);
        final latestSugarEntry = healthState.vitals.firstWhere((v) => v.bloodSugar > 0, orElse: () => healthState.vitals.first);
        final latestHREntry    = healthState.vitals.firstWhere((v) => v.heartRate > 0, orElse: () => healthState.vitals.first);

        if (latestBPEntry.systolic > 0) {
          latestSystolic = latestBPEntry.systolic;
          latestDiastolic = latestBPEntry.diastolic;
        }
        if (latestSugarEntry.bloodSugar > 0) latestSugar = latestSugarEntry.bloodSugar;
        if (latestHREntry.heartRate > 0) latestHR = latestHREntry.heartRate;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Health Analytics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVitalsSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
        label: Text(
          'Log Vitals',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section - Medical Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildSectionHeader('Medical Summary', Icons.analytics_outlined),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Row 1: Prescriptions + Reminders
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.medication_liquid_rounded,
                          label: 'Active Prescriptions',
                          value: '$activePrescriptions',
                          unit: 'Rx',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.alarm_on_rounded,
                          label: 'Reminder Plans',
                          value: '$totalSchedules',
                          unit: 'Plans',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Row 2: Vitals Logged + Latest BP
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.show_chart_rounded,
                          label: 'Vitals Logged',
                          value: '$totalVitalsLogged',
                          unit: 'Entries',
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: latestSystolic > 0
                            ? _buildSummaryCard(
                                icon: Icons.favorite_rounded,
                                label: 'Latest BP',
                                value: '$latestSystolic/$latestDiastolic',
                                unit: 'mmHg',
                                color: const Color(0xFFE53935),
                              )
                            : _buildSummaryCard(
                                icon: Icons.favorite_border_rounded,
                                label: 'Latest BP',
                                value: '—',
                                unit: 'Not logged',
                                color: AppColors.textHint,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Health Status Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildHealthStatusBar(
                activePrescriptions: activePrescriptions,
                totalSchedules: totalSchedules,
                totalVitalsLogged: totalVitalsLogged,
                latestSystolic: latestSystolic,
                latestDiastolic: latestDiastolic,
                latestSugar: latestSugar,
                latestHR: latestHR,
              ),
            ),

            // Middle Section - BP Analytics
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSectionHeader('Overall BP Average', Icons.monitor_heart_outlined),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _buildBloodPressureAverage(avgSystolic, avgDiastolic, bpCount),
            ),
            
            // Bottom Section - Vitals Log
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSectionHeader('Vitals Log', Icons.monitor_heart_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: BlocBuilder<HealthBloc, HealthState>(
                builder: (context, state) {
                  if (state is HealthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is HealthError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: GoogleFonts.inter(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (state is HealthLoaded) {
                    if (state.vitals.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.health_and_safety_outlined, size: 60, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No vitals logged yet.',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Log Vitals" to add your first reading.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.vitals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildVitalCard(state.vitals[index]);
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }



  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusBar({
    required int activePrescriptions,
    required int totalSchedules,
    required int totalVitalsLogged,
    required int latestSystolic,
    required int latestDiastolic,
    required double latestSugar,
    required int latestHR,
  }) {
    // Smart contextual tip logic
    String tip;
    IconData tipIcon;
    Color tipColor;

    if (activePrescriptions > 0 && totalSchedules == 0) {
      tip = 'You have prescriptions but no reminders set. Tap ⋮ in Health Vault to generate a schedule.';
      tipIcon = Icons.notification_important_rounded;
      tipColor = AppColors.warning;
    } else if (totalVitalsLogged == 0) {
      tip = 'No vitals yet. Tap "Log Vitals" or save a prescription with readings to start tracking.';
      tipIcon = Icons.tips_and_updates_rounded;
      tipColor = AppColors.primary;
    } else if (latestSystolic >= 140 || latestDiastolic >= 90) {
      tip = 'Your latest BP ($latestSystolic/$latestDiastolic mmHg) appears elevated. Consider consulting your doctor.';
      tipIcon = Icons.warning_amber_rounded;
      tipColor = AppColors.error;
    } else if (latestSugar > 200) {
      tip = 'Your latest blood sugar (${latestSugar.toStringAsFixed(0)} mg/dL) is high. Consider monitoring closely.';
      tipIcon = Icons.warning_amber_rounded;
      tipColor = AppColors.error;
    } else if (latestSystolic > 0 && latestSystolic < 140) {
      tip = 'Your BP looks healthy! Keep logging to track long-term trends.';
      tipIcon = Icons.check_circle_rounded;
      tipColor = AppColors.success;
    } else {
      tip = 'Scan prescriptions or record consultations to build your health timeline.';
      tipIcon = Icons.lightbulb_outline_rounded;
      tipColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tipColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: tipColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureAverage(int sys, int dia, int count) {
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'Keep tracking BP Vitals to see average trends.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average Blood Pressure',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$sys/$dia',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'mmHg',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Calculated over $count logs',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                ),
              )
            ],
          ),
          Icon(Icons.favorite_rounded, size: 60, color: Colors.white.withValues(alpha: 0.2)),
        ],
      ),
    );
  }


  Widget _buildVitalCard(HealthVitalsModel vital) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Build only metrics that have real data
    final metrics = <Widget>[];

    void addMetric(String label, String value, String unit, Color color) {
      if (metrics.isNotEmpty) {
        metrics.add(Container(width: 1, height: 36, color: AppColors.border.withValues(alpha: 0.5)));
      }
      metrics.add(Expanded(child: _buildVitalMetric(label, value, unit, color)));
    }

    if (vital.systolic > 0 && vital.diastolic > 0) {
      addMetric('Blood Pressure', '${vital.systolic}/${vital.diastolic}', 'mmHg', const Color(0xFFE53935));
    }
    if (vital.bloodSugar > 0) {
      addMetric('Blood Sugar', vital.bloodSugar.toStringAsFixed(1), 'mg/dL', AppColors.accent);
    }
    if (vital.heartRate > 0) {
      addMetric('Heart Rate', '${vital.heartRate}', 'bpm', AppColors.secondary);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(vital.timestamp),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        timeFormat.format(vital.timestamp),
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              // Delete button
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Delete Entry?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      content: Text(
                        'This vitals reading will be permanently removed from your health log.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && _userId != null) {
                    context.read<HealthBloc>().add(DeleteHealthVitals(vitalsId: vital.id, userId: _userId!));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(children: metrics),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No readings recorded for this entry.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalMetric(String label, String value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
