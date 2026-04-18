import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medassist/presentation/blocs/notification/notification_bloc.dart';
import 'package:medassist/presentation/blocs/notification/notification_event_state.dart';
import 'package:medassist/presentation/blocs/auth/auth_bloc.dart';
import 'package:medassist/presentation/blocs/auth/auth_event_state.dart';
import 'package:medassist/presentation/blocs/family/active_profile_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getIconForType(String type) {
    if (type == 'Reminder') return Icons.medication_liquid_rounded;
    if (type == 'Vault') return Icons.document_scanner_rounded;
    if (type == 'Health') return Icons.monitor_heart_rounded;
    return Icons.smart_toy_rounded; // System
  }

  Color _getColorForType(String type) {
    if (type == 'Reminder') return AppColors.primary;
    if (type == 'Vault') return AppColors.accent;
    if (type == 'Health') return const Color(0xFFE53935);
    return AppColors.secondary; // System
  }

  @override
  Widget build(BuildContext context) {
    // Get currently active composite user Id
    final baseAuth = context.watch<AuthBloc>().state;
    String baseId = 'unauth';
    String baseName = 'User';
    if (baseAuth is AuthAuthenticated) {
      baseId = baseAuth.user.id;
      baseName = baseAuth.user.fullName;
    }
    final compositeId = context.watch<ActiveProfileCubit>().getCompositeUserId(baseId, baseName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllNotificationsAsRead(compositeId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primary),
              );
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<NotificationBloc>().add(ClearAllNotifications(compositeId));
            },
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is NotificationLoaded) {
            final notifications = state.notifications;
            
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'re all caught up.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final notify = notifications[index];
                final isRead = notify.isRead;
                final color = _getColorForType(notify.type);

                return GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      context.read<NotificationBloc>().add(MarkNotificationAsRead(notify));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRead 
                            ? AppColors.border.withValues(alpha: 0.5)
                            : color.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        if (!isRead)
                          BoxShadow(
                            color: color.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(notify.type),
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notify.type,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(notify.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notify.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notify.body,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isRead 
                                      ? AppColors.textSecondary 
                                      : AppColors.textPrimary.withValues(alpha: 0.8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
