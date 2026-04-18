import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';
import 'package:medassist/data/models/reminder_models.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Static service for scheduling / cancelling local notifications.
/// Call [initialize] once from main() before runApp.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Tap navigation stream ─────────────────────────────────────────────────
  // Emits { modelId, userId } JSON string when a notification is tapped.
  // Listen to this stream from the top-level app widget to navigate.

  static final StreamController<String> _tapController =
      StreamController<String>.broadcast();

  static Stream<String> get notificationTaps => _tapController.stream;

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: darwinSettings),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Request permissions (Android 13+ / iOS)
    await _requestPermissions();

    _initialized = true;
  }

  // Called when app is in foreground or background (not killed)
  static void _onTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      _tapController.add(response.payload!);
    }
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Cold-start: tap when app was fully killed ─────────────────────────────
  // Call this once after initialize() to handle the launch notification.
  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Cancel ALL scheduled notifications then re-schedule for every model.
  static Future<void> rescheduleAll(
      List<PrescriptionReminderModel> models,
      List<List<ReminderSlot>> decodedSlots) async {
    await _plugin.cancelAll();

    for (int mIdx = 0; mIdx < models.length; mIdx++) {
      final model = models[mIdx];
      final slots =
          mIdx < decodedSlots.length ? decodedSlots[mIdx] : <ReminderSlot>[];
      await _scheduleForModel(model, slots);
    }
  }

  // ── Private scheduling ────────────────────────────────────────────────────

  static Future<void> _scheduleForModel(
      PrescriptionReminderModel model, List<ReminderSlot> slots) async {
    for (int sIdx = 0; sIdx < slots.length; sIdx++) {
      final slot = slots[sIdx];
      // Construct list of all medicine names for this slot
      final allMeds = slot.periods
          .expand((p) => p.medicines)
          .map((m) => m.name)
          .join(', ');

      final payloadMap = {
        'modelId': model.id,
        'userId': model.userId,
        'slotId': slot.id,
        'medicineNames': allMeds,
      };

      for (final period in slot.periods) {
        final days = period.endDate.difference(period.startDate).inDays + 1;
        for (int dayOffset = 0; dayOffset < days; dayOffset++) {
          final date = period.startDate.add(Duration(days: dayOffset));
          final scheduled = _buildTZDateTime(date, slot.scheduledTime);

          if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

          final id = _notifId(model.id, sIdx, date);
          final title =
              '${slot.slotEmoji} ${slot.slotName} — ${model.prescriptionTitle}';

          // Full list of medicines for expanded BigText
          final bodyLines = period.medicines
              .map((m) =>
                  '💊 ${m.name}${m.dosage.isNotEmpty ? "  •  ${m.dosage}" : ""}')
              .toList();
          final body = bodyLines.join('\n');
          // Collapsed summary (first medicine + count)
          final summaryText = period.medicines.length > 1
              ? '${period.medicines.first.name} + ${period.medicines.length - 1} more'
              : period.medicines.first.name;

          print('🔔 ALARM: Scheduling for ${scheduled.toString()} | Meds: $allMeds');

          final androidDetails = AndroidNotificationDetails(
            'medassist_final_alarm_v3', // V3 to wipe out old settings
            'Medication Alarms',
            channelDescription:
                'Critical medication alerts from MedAssist',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',



            // ── BigText: shows full list when notification is expanded ──
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: summaryText,
              htmlFormatContent: false,
              htmlFormatContentTitle: false,
            ),
          );

          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduled,
            NotificationDetails(
              android: androidDetails,
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: jsonEncode(payloadMap..addAll({'title': title, 'body': body})),
          );
        }
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static tz.TZDateTime _buildTZDateTime(DateTime date, String scheduledTime) {
    int hour = 8;
    int minute = 0;
    try {
      final isPM = scheduledTime.contains('PM');
      final timePart = scheduledTime
          .replaceAll(' AM', '')
          .replaceAll(' PM', '')
          .replaceAll('AM', '')
          .replaceAll('PM', '');
      final parts = timePart.trim().split(':');
      hour = int.parse(parts[0]);
      minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
    } catch (_) {}

    return tz.TZDateTime(
        tz.local, date.year, date.month, date.day, hour, minute);
  }

  static int _notifId(String modelId, int slotIdx, DateTime date) {
    final daysSinceEpoch = date.millisecondsSinceEpoch ~/ 86400000;
    final hash = modelId.hashCode.abs();
    return ((hash % 10000) * 1000 + slotIdx * 366 + (daysSinceEpoch % 366))
            .abs() %
        2000000000;
  }

  /// Fire a notification in 5 seconds for testing
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'medassist_test_channel',
      'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    final payload = jsonEncode({
      'medicineNames': 'Test Medicine (Panadol)',
      'title': '🔔 Test Alarm',
      'body': 'This is a test of your intelligent alarm system.',
    });

    await _plugin.zonedSchedule(
      999,
      '🔔 Test Alarm',
      'It\'s time to take your Test Medicine.',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medassist_final_alarm_v3',
          'Medication Alarms',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),


      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Immediately shows a persistent confirmation notification
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    print('🔔 ALARM: Showing instant confirmation: $title');
    const androidDetails = AndroidNotificationDetails(
      'medassist_final_alarm_v3',
      'Medication Alarms',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    await _plugin.show(
      888,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}

// Must be a top-level function for background notification response
@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  // Background tap is handled by _onTap when the app resumes
}
