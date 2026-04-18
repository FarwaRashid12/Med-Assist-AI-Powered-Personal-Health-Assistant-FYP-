import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/health/health_bloc.dart';
import '../../blocs/health/health_event_state.dart';
import '../../blocs/reminder/reminder_bloc.dart';
import '../../blocs/reminder/reminder_event_state.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event_state.dart';
import '../consult/consult_screen.dart';
import '../health/health_screen.dart';
import '../reports/reports_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reminder_models.dart';
import '../../widgets/reminders/slot_focus_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.document_scanner_rounded, label: 'Prescription'),
    _NavItem(icon: Icons.mic_rounded, label: 'Consult'),
    _NavItem(icon: Icons.monitor_heart_rounded, label: 'Health'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
  ];

  String? _currentCompositeId;

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
      if (_currentCompositeId != newId) {
        _currentCompositeId = newId;
        context.read<ReminderBloc>().add(LoadReminders(_currentCompositeId!));
        // Also load vitals for the home screen health summary
        context.read<HealthBloc>().add(LoadHealthVitals(_currentCompositeId!));
        // Initialize notifications pipeline
        context.read<NotificationBloc>().add(LoadNotifications(_currentCompositeId!));
        // Pre-fetch prescriptions for chatbot system context
        context.read<PrescriptionBloc>().add(LoadSavedPrescriptions(_currentCompositeId!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = (state is AuthAuthenticated)
        ? state.user
        : (state is AuthRegisterSuccess ? state.user : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'MedAssist',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: _selectedIndex == 0 
          ? _buildDashboard(user?.fullName ?? 'User') 
          : _selectedIndex == 2 
              ? const ConsultScreen()
              : _selectedIndex == 3
                  ? const HealthScreen()
                  : _selectedIndex == 4
                      ? const ReportsScreen()
                      : _buildComingSoon(_navItems[_selectedIndex].label),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/chatbot'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            )
          : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) {
              if (i == 1) {
                context.push('/scanner');
              } else {
                setState(() => _selectedIndex = i);
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            selectedLabelStyle: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
            backgroundColor: Colors.white,
            elevation: 0,
            items: _navItems
                .asMap()
                .entries
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(
                          _selectedIndex == e.key ? 8 : 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == e.key
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(e.value.icon),
                    ),
                    label: e.value.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(String name) {
    final activeProfileName = context.watch<ActiveProfileCubit>().state;
    final displayProfileName = activeProfileName.isEmpty ? name : activeProfileName;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Greeting card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildGreetingCard(displayProfileName),
          ),
          const SizedBox(height: 32),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildQuickActions(),
          ),
          const SizedBox(height: 32),

          // Today's reminders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Reminders",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/reminders'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTodaysReminders(),
          ),

          const SizedBox(height: 32),

          // Health summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Health Summary',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthTiles(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, 👋',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.split(' ').first,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🏥  Stay on top of your health today!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.document_scanner_rounded,
        label: 'Scan Rx',
        color: AppColors.primary,
        bgColor: AppColors.primarySurface,
        onTap: () => context.push('/scanner'),
      ),
      _QuickAction(
        icon: Icons.mic_rounded,
        label: 'Consult',
        color: const Color(0xFF6C5CE7),
        bgColor: const Color(0xFFEDE9FD),
        onTap: () => setState(() => _selectedIndex = 2),
      ),
      _QuickAction(
        icon: Icons.favorite_rounded,
        label: 'Vitals',
        color: AppColors.secondary,
        bgColor: AppColors.secondarySurface,
        onTap: () => setState(() => _selectedIndex = 3),
      ),
      _QuickAction(
        icon: Icons.folder_special_rounded,
        label: 'Vault',
        color: AppColors.accent,
        bgColor: AppColors.accentSurface,
        onTap: () => context.push('/vault'),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: a.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: a.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, color: a.color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Today's Reminders — real data ────────────────────────────────────────

  Widget _buildTodaysReminders() {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is ReminderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = state is RemindersLoaded
            ? state.reminders
            : state is ReminderGenerated
                ? state.allReminders
                : [];

        if (reminders.isEmpty) return _buildEmptyReminders();

        final today = DateTime.now();
        final todaySlots = <({ReminderSlot slot, dynamic model})>[];

        for (final model in reminders) {
          for (final j in model.reminderSlotsJson) {
            try {
              final slot = ReminderSlot.fromJson(
                  jsonDecode(j) as Map<String, dynamic>);
              for (final period in slot.periods) {
                if (!today.isBefore(period.startDate) &&
                    !today.isAfter(period.endDate)) {
                  todaySlots.add((slot: slot, model: model));
                  break;
                }
              }
            } catch (_) {}
          }
        }

        if (todaySlots.isEmpty) return _buildEmptyReminders();

        return Column(
          children: todaySlots.map((entry) {
            final slot = entry.slot;
            final model = entry.model;

            // Count medicines active today
            int medCount = 0;
            for (final period in slot.periods) {
              if (!today.isBefore(period.startDate) &&
                  !today.isAfter(period.endDate)) {
                medCount = period.medicines.length;
                break;
              }
            }

            return GestureDetector(
              onTap: () => SlotFocusBottomSheet.show(
                context,
                model: model,
                slotId: slot.id,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Text(slot.slotEmoji,
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.slotName,
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          '${slot.scheduledTime}  •  $medCount medicine${medCount != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Tap to view',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ]),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyReminders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.alarm_on_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No reminders yet',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Add a prescription to auto-generate reminders',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTiles() {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        // Extract latest reading per metric from vitals (newest-first)
        String bpValue = '--/--';
        String sugarValue = '--';
        String hrValue = '--';

        if (state is HealthLoaded && state.vitals.isNotEmpty) {
          final bpEntry = state.vitals.firstWhere(
            (v) => v.systolic > 0 && v.diastolic > 0,
            orElse: () => state.vitals.first,
          );
          final sugarEntry = state.vitals.firstWhere(
            (v) => v.bloodSugar > 0,
            orElse: () => state.vitals.first,
          );
          final hrEntry = state.vitals.firstWhere(
            (v) => v.heartRate > 0,
            orElse: () => state.vitals.first,
          );

          if (bpEntry.systolic > 0) bpValue = '${bpEntry.systolic}/${bpEntry.diastolic}';
          if (sugarEntry.bloodSugar > 0) sugarValue = sugarEntry.bloodSugar.toStringAsFixed(1);
          if (hrEntry.heartRate > 0) hrValue = '${hrEntry.heartRate}';
        }

        final tiles = [
          _HealthTile(
            label: 'Blood Pressure', value: bpValue, unit: 'mmHg',
            icon: Icons.favorite_rounded, color: const Color(0xFFE53935),
            bgColor: const Color(0xFFFFF0F0),
            hasData: bpValue != '--/--',
          ),
          _HealthTile(
            label: 'Blood Sugar', value: sugarValue, unit: 'mg/dL',
            icon: Icons.water_drop_rounded, color: AppColors.accent,
            bgColor: AppColors.accentSurface,
            hasData: sugarValue != '--',
          ),
          _HealthTile(
            label: 'Heart Rate', value: hrValue, unit: 'bpm',
            icon: Icons.monitor_heart_rounded, color: AppColors.primary,
            bgColor: AppColors.primarySurface,
            hasData: hrValue != '--',
          ),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.none,
          child: Row(
            children: tiles.map((t) {
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: Container(
                  width: 148,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: t.hasData
                          ? t.color.withValues(alpha: 0.2)
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: t.hasData
                            ? t.color.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
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
                          color: t.hasData ? t.color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.icon, color: t.hasData ? t.color : AppColors.textHint, size: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.value,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: t.hasData ? AppColors.textPrimary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.unit,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: t.hasData ? t.color : AppColors.textHint,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildComingSoon(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon\nThis feature is being built!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class _HealthTile {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool hasData;
  const _HealthTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.hasData = false,
  });
}
