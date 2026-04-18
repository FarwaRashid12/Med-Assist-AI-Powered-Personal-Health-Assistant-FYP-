import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'data/models/user_model.dart';
import 'data/models/health_vitals_model.dart';
import 'data/models/prescription_reminder_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/firebase_service.dart';
import 'data/repositories/consultation_repository.dart';
import 'data/models/reminder_models.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event_state.dart';
import 'presentation/blocs/consultation/consultation_bloc.dart';
import 'data/repositories/health_local_datasource.dart';
import 'data/repositories/health_repository.dart';
import 'data/repositories/prescription_repository.dart';
import 'data/repositories/reminder_local_datasource.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/models/saved_prescription_model.dart';
import 'presentation/blocs/health/health_bloc.dart';
import 'presentation/blocs/prescription/prescription_bloc.dart';
import 'presentation/blocs/reminder/reminder_bloc.dart';
import 'presentation/blocs/family/family_bloc.dart';
import 'presentation/blocs/family/active_profile_cubit.dart';
import 'data/repositories/chatbot_repository.dart';
import 'presentation/blocs/chatbot/chatbot_bloc.dart';
import 'presentation/blocs/recording/recording_bloc.dart';
import 'data/models/family_profile_model.dart';
import 'data/models/saved_recording_model.dart';
import 'data/repositories/family_repository.dart';
import 'data/repositories/recording_repository.dart';
import 'data/models/notification_model.dart';
import 'data/repositories/notification_local_datasource.dart';
import 'data/repositories/notification_repository.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/widgets/reminders/slot_focus_bottom_sheet.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(HealthVitalsModelAdapter());
  Hive.registerAdapter(SavedPrescriptionModelAdapter());
  Hive.registerAdapter(PrescriptionReminderModelAdapter());
  Hive.registerAdapter(FamilyProfileModelAdapter());
  Hive.registerAdapter(SavedRecordingModelAdapter());
  Hive.registerAdapter(NotificationModelAdapter());

  // Initialize notification service (timezone + plugin)
  await NotificationService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final firebaseService = FirebaseService();
  final authRepository = AuthRepository(firebaseService);
  final healthRepository = HealthRepository(HealthLocalDataSource());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: firebaseService),
        RepositoryProvider.value(value: healthRepository),
        RepositoryProvider(create: (_) => ConsultationRepository()),
        RepositoryProvider(create: (_) => PrescriptionRepository()),
        RepositoryProvider(
            create: (_) => ReminderRepository(ReminderLocalDataSource())),
        RepositoryProvider(create: (_) => FamilyRepository()),
        RepositoryProvider(create: (_) => RecordingRepository()),
        RepositoryProvider(
            create: (_) => NotificationRepository(NotificationLocalDataSource())),
      ],
      child: const MedAssistApp(),
    ),
  );
}

class MedAssistApp extends StatefulWidget {
  const MedAssistApp({super.key});

  @override
  State<MedAssistApp> createState() => _MedAssistAppState();
}

class _MedAssistAppState extends State<MedAssistApp> {
  GoRouter? _router;
  StreamSubscription<String>? _notifSub;
  Timer? _alarmWatcher;
  final Set<String> _triggeredAlarmIds = {};

  @override
  void initState() {
    super.initState();
    _startAlarmWatcher();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _alarmWatcher?.cancel();
    super.dispose();
  }

  void _startAlarmWatcher() {
    _alarmWatcher = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkForUpcomingAlarms();
    });
  }

  Future<void> _checkForUpcomingAlarms() async {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else if (authState is AuthRegisterSuccess) {
      userId = authState.user.id;
    }

    if (userId == null || _router == null) return;

    try {
      final repo = context.read<ReminderRepository>();
      final reminders = await repo.loadAll(userId);
      final now = DateTime.now();
      
      // Heartbeat for console verification
      print('💓 WATCHER: Checking at ${now.hour}:${now.minute.toString().padLeft(2, '0')}...');

      for (final model in reminders) {
        final slots = repo.decodeSlots(model);
        for (final slot in slots) {
          final timeParts = _parseTime(slot.scheduledTime);
          if (timeParts == null) continue;

          // Check if current hour/minute matches (lenient check)
          if (now.hour == timeParts['hour'] && now.minute == timeParts['minute']) {
            final alarmId = '${model.id}_${slot.id}_${now.day}';
            
            if (!_triggeredAlarmIds.contains(alarmId)) {
              _triggeredAlarmIds.add(alarmId);
              
              // Extract medicine names for the voice
              final medNames = slot.periods
                  .expand((p) => p.medicines)
                  .map((m) => m.name)
                  .join(', ');

              final payload = {
                'title': '🔔 Medication Time',
                'body': 'It\'s time to take: $medNames',
                'medicineNames': medNames,
              };

              print('🔔 ALARM WATCHER TRIGGER: Pushing Alarm Screen for $medNames');
              _router!.push(AppRouter.alarm, extra: payload);
            }
          }
        }
      }
    } catch (e) {
      print('❌ ALARM WATCHER ERROR: $e');
    }
  }

  Map<String, int>? _parseTime(String time) {
    try {
      final isPM = time.contains('PM');
      final cleanTime = time.replaceAll(' AM', '').replaceAll(' PM', '').trim();
      final parts = cleanTime.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return {'hour': hour, 'minute': minute};
    } catch (_) {
      return null;
    }
  }

  // ── Notification tap handler ──────────────────────────────────────────────

  void _listenNotificationTaps() {
    _notifSub?.cancel();
    _notifSub = NotificationService.notificationTaps.listen((payload) {
      _queueOrHandlePayload(payload);
    });

    // Handle cold-start (app was killed, opened via notification)
    NotificationService.getLaunchPayload().then((payload) {
      if (payload != null) _queueOrHandlePayload(payload);
    });
  }

  void _queueOrHandlePayload(String payload) {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated || authState is AuthRegisterSuccess) {
      // If already authenticated, just handle it (add small delay for router layout if cold start)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _handleNotifPayload(payload);
      });
    } else {
      // Wait for auth to resolve
      StreamSubscription<AuthState>? sub;
      sub = context.read<AuthBloc>().stream.listen((state) {
        if (state is AuthAuthenticated || state is AuthRegisterSuccess) {
          sub?.cancel();
          // Small delay to let GoRouter settle on home before pushing detail
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _handleNotifPayload(payload);
          });
        }
      });
    }
  }

  Future<void> _handleNotifPayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (mounted && _router != null) {
        // Direct navigation to the intelligent Alarm Screen
        _router!.push(AppRouter.alarm, extra: data);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(context.read<AuthRepository>())
            ..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) =>
              ConsultationBloc(context.read<ConsultationRepository>()),
        ),
        BlocProvider(
          create: (context) => HealthBloc(context.read<HealthRepository>()),
        ),
        BlocProvider(
          create: (context) => PrescriptionBloc(
            context.read<PrescriptionRepository>(),
            context.read<FirebaseService>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              ReminderBloc(context.read<ReminderRepository>()),
        ),
        BlocProvider(
          create: (context) => FamilyBloc(context.read<FamilyRepository>()),
        ),
        BlocProvider(
          create: (context) => RecordingBloc(context.read<RecordingRepository>()),
        ),
        BlocProvider(
          create: (context) => ActiveProfileCubit(),
        ),
        BlocProvider(
          create: (context) => NotificationBloc(context.read<NotificationRepository>()),
        ),
        BlocProvider(
          create: (context) => ChatbotBloc(ChatbotRepository()),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Create router once and store reference for notification navigation
          _router ??= AppRouter.createRouter(context.read<AuthBloc>());

          // Start listening after first build
          if (_notifSub == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _listenNotificationTaps());
          }

          return MaterialApp.router(
            title: 'MedAssist',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: _router!,
          );
        },
      ),
    );
  }
}
