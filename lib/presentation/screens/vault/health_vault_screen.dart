import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/saved_prescription_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/reminder/reminder_bloc.dart';
import '../../blocs/reminder/reminder_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event_state.dart';
import '../../../data/models/notification_model.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class HealthVaultScreen extends StatefulWidget {
  const HealthVaultScreen({super.key});

  @override
  State<HealthVaultScreen> createState() => _HealthVaultScreenState();
}

class _HealthVaultScreenState extends State<HealthVaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCards = {};
  String _searchQuery = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) setState(() => _currentlyPlayingId = null);
      }
    });
  }

  void _loadPrescriptions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final profileCubit = context.read<ActiveProfileCubit>();
      final queryId = profileCubit.getCompositeUserId(authState.user.id, authState.user.fullName);
      context.read<PrescriptionBloc>().add(LoadSavedPrescriptions(queryId));
    } else if (authState is AuthRegisterSuccess) {
      final profileCubit = context.read<ActiveProfileCubit>();
      final queryId = profileCubit.getCompositeUserId(authState.user.id, authState.user.fullName);
      context.read<PrescriptionBloc>().add(LoadSavedPrescriptions(queryId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateReminders(SavedPrescriptionModel p) async {
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
      context.read<ReminderBloc>().add(GenerateReminders(prescription: p, startDate: picked));
    }
  }

  Future<void> _showEditDialog(SavedPrescriptionModel p) async {
    final doctorCtrl = TextEditingController(text: p.doctorName == 'Not mentioned' ? '' : p.doctorName);
    final clinicCtrl = TextEditingController(text: p.clinicName == 'Not mentioned' ? '' : p.clinicName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Info', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: doctorCtrl,
              decoration: InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clinicCtrl,
              decoration: InputDecoration(
                labelText: 'Clinic / Hospital',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      String? userId;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) userId = authState.user.id;
      if (authState is AuthRegisterSuccess) userId = authState.user.id;
      
      if (userId != null) {
        final updatedP = SavedPrescriptionModel(
          id: p.id,
          userId: p.userId,
          clinicName: clinicCtrl.text.trim().isEmpty ? 'Not mentioned' : clinicCtrl.text.trim(),
          doctorName: doctorCtrl.text.trim().isEmpty ? 'Not mentioned' : doctorCtrl.text.trim(),
          medicineNames: p.medicineNames,
          medicineDosages: p.medicineDosages,
          medicineFrequencies: p.medicineFrequencies,
          medicineTimings: p.medicineTimings,
          medicineDurations: p.medicineDurations,
          notes: p.notes,
          vitals: p.vitals,
          savedAt: p.savedAt,
        );
        context.read<PrescriptionBloc>().add(UpdateSavedPrescription(updatedP, userId));
      }
    }
  }

  Future<void> _showDeletePrescriptionDialog(SavedPrescriptionModel p) async {
    final title = p.doctorName != 'Not mentioned' ? p.doctorName : p.clinicName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Prescription?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$title"?\n\n'
          'This will permanently remove the saved prescription and any associated reminders.',
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
      String? userId;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) userId = authState.user.id;
      if (authState is AuthRegisterSuccess) userId = authState.user.id;

      if (userId != null) {
        String? rId;
        final reminderState = context.read<ReminderBloc>().state;
        final list = (reminderState is RemindersLoaded) 
            ? reminderState.reminders 
            : (reminderState is ReminderGenerated ? reminderState.allReminders : []);
            
        for (var r in list) {
           if(r.prescriptionId == p.id) { rId = r.id; break; }
        }
        
        if (rId != null) {
            context.read<ReminderBloc>().add(DeleteReminder(reminderId: rId, userId: userId));
        }
        
        context.read<PrescriptionBloc>().add(DeleteSavedPrescription(p.id, userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReminderBloc, ReminderState>(
      listener: (context, state) {
        if (state is ReminderGenerated) {
             final authState = context.read<AuthBloc>().state;
             String? uId;
             if (authState is AuthAuthenticated) uId = authState.user.id;
             if (authState is AuthRegisterSuccess) uId = authState.user.id;
             if (uId != null) {
                 final notification = NotificationModel(
                   id: const Uuid().v4(),
                   userId: uId,
                   title: 'Reminder Plan Generated',
                   body: 'A new medication schedule was created from your prescription.',
                   type: 'Reminder',
                   timestamp: DateTime.now(),
                 );
                 context.read<NotificationBloc>().add(AddNotification(notification));
             }

             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text('✅ Reminders generated successfully!'),
                 backgroundColor: AppColors.success,
                 behavior: SnackBarBehavior.floating,
                 action: SnackBarAction(
                   label: 'View Reminders',
                   textColor: Colors.white,
                   onPressed: () => context.push(AppRouter.reminders),
                 ),
             ));
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
        title: Text(
          'Health Vault',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by doctor, clinic, or medicine...',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                        onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
              builder: (context, state) {
                if (state is SavedPrescriptionsLoaded) {
                  var items = state.prescriptions;

                  // Filter by search
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    items = items.where((p) =>
                        p.clinicName.toLowerCase().contains(q) ||
                        p.doctorName.toLowerCase().contains(q) ||
                        p.medicineSummary.toLowerCase().contains(q)
                    ).toList();
                  }

                  if (items.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildPrescriptionCard(items[index], index),
                  );
                }

                if (state is PrescriptionError) {
                  return Center(child: Text(state.message, style: GoogleFonts.inter(color: AppColors.error)));
                }

                // Initial load or analyzing states - show empty
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
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
            Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text('No Prescriptions Saved', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Scan a prescription and save it to see it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(SavedPrescriptionModel p, int index) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isExpanded = _expandedCards.contains(p.id);

    // Smart display logic
    final hasDoctor = p.doctorName.isNotEmpty && p.doctorName != 'Not mentioned';
    final hasClinic = p.clinicName.isNotEmpty && p.clinicName != 'Not mentioned';
    final primaryTitle = hasDoctor ? p.doctorName : (hasClinic ? p.clinicName : 'Unknown Doctor');
    final subtitle = hasDoctor && hasClinic ? p.clinicName : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExpanded ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(p.id);
                } else {
                  _expandedCards.add(p.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),

                // Main Info block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor name — primary headline
                      Text(
                        primaryTitle,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Clinic subtitile
                      if (subtitle != null)
                        Row(
                          children: [
                            const Icon(Icons.local_hospital_rounded, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Date + time on same row, compact
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Text(
                            dateFormat.format(p.savedAt),
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Text(
                            timeFormat.format(p.savedAt),
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right side: badges + actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Meds count + media indicators row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.imagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.image_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.6)),
                          ),
                        if (p.audioPath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.mic_rounded, size: 14, color: AppColors.secondary.withValues(alpha: 0.7)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${p.medicineCount} meds',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Expand + menu row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'generate') _generateReminders(p);
                            if (val == 'edit') _showEditDialog(p);
                            if (val == 'delete') _showDeletePrescriptionDialog(p);
                          },
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 18),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'generate',
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text('Generate Reminders', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 18),
                          const SizedBox(width: 10),
                          Text('Edit Doctor/Clinic', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
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
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

          // Medicines list
          ...List.generate(p.medicineCount, (i) {
            final duration = (i < p.medicineDurations.length) ? p.medicineDurations[i] : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.medicineNames[i],
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Dosage
                            if (p.medicineDosages[i].isNotEmpty)
                              _buildBadge(p.medicineDosages[i], AppColors.primarySurface, AppColors.primary),
                            // Frequency
                            if (p.medicineFrequencies[i].isNotEmpty)
                              _buildBadge(p.medicineFrequencies[i], AppColors.surfaceVariant, AppColors.textSecondary),
                            // Duration
                            if (duration.isNotEmpty)
                              _buildBadge('📅 $duration', const Color(0xFFF0FFF4), AppColors.accent),
                          ],
                        ),
                        if (p.medicineTimings[i].isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            p.medicineTimings[i],
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          if (p.notes.trim().isNotEmpty || p.vitals.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            
            if (p.notes.trim().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.speaker_notes_rounded, color: AppColors.textHint, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consultation Notes', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(p.notes, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
              if (p.vitals.isNotEmpty) const SizedBox(height: 14),
            ],
            
            if (p.vitals.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Icon(Icons.monitor_heart_rounded, color: AppColors.error, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text('Encounter Vitals', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.vitals.entries.map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${e.key}: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text(e.value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                                ],
                              ),
                            )).toList(),
                          )
                       ],
                     ),
                   ),
                ],
              ),
            ],

            // Media Buttons
            if (p.imagePath != null || p.audioPath != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (p.imagePath != null)
                    _buildMediaButton(
                      icon: Icons.image_search_rounded,
                      label: 'View Original',
                      color: AppColors.primary,
                      onTap: () => _showImageDialog(p.imagePath!),
                    ),
                  if (p.audioPath != null)
                    _buildMediaButton(
                      icon: _currentlyPlayingId == p.id
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      label: _currentlyPlayingId == p.id ? 'Stop Audio' : 'Listen Recording',
                      color: AppColors.secondary,
                      onTap: () => _toggleAudio(p.id, p.audioPath!),
                    ),
                ],
              ),
            ],
          ]
          ],
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  void _toggleAudio(String prescriptionId, String audioPath) async {
    if (_currentlyPlayingId == prescriptionId) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      setState(() => _currentlyPlayingId = prescriptionId);
      await _audioPlayer.play(DeviceFileSource(audioPath));
    }
  }

  void _showImageDialog(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file not found on device.'), backgroundColor: AppColors.error),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: -16,
              right: -16,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
