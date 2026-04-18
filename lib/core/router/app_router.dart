import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medassist/presentation/blocs/auth/auth_bloc.dart';
import 'package:medassist/presentation/blocs/auth/auth_event_state.dart';
import 'package:medassist/presentation/screens/splash/splash_screen.dart';
import 'package:medassist/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:medassist/presentation/screens/auth/login_screen.dart';
import 'package:medassist/presentation/screens/auth/register_screen.dart';
import 'package:medassist/presentation/screens/home/home_screen.dart';
import 'package:medassist/presentation/screens/home/notifications_screen.dart';
import 'package:medassist/presentation/screens/profile/profile_screen.dart';
import 'package:medassist/presentation/screens/prescription/prescription_scanner_screen.dart';
import 'package:medassist/presentation/screens/prescription/ocr_verification_screen.dart';
import 'package:medassist/presentation/screens/reminders/reminders_screen.dart';
import 'package:medassist/presentation/screens/reminders/reminder_detail_screen.dart';
import 'package:medassist/presentation/screens/reminders/alarm_screen.dart';
import 'package:medassist/presentation/screens/vault/health_vault_screen.dart';
import 'package:medassist/presentation/screens/emergency/emergency_qr_screen.dart';
import 'package:medassist/presentation/screens/chatbot/chatbot_screen.dart';
import 'package:medassist/data/models/prescription_reminder_model.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  static const String ocrVerification = '/ocr-verification';
  static const String notifications = '/notifications';
  static const String reminders = '/reminders';
  static const String reminderDetail = '/reminder-detail';
  static const String vault = '/vault';
  static const String qrCard = '/qr-card';
  static const String chatbot = '/chatbot';
  static const String alarm = '/alarm';

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final loc = state.matchedLocation;
        final isOnSplash = loc == splash;
        final isOnOnboarding = loc == onboarding;
        final isOnAuth = loc == login || loc == register;
        final isPublic = isOnSplash || isOnOnboarding || isOnAuth;

        if (authState is AuthLoading || authState is AuthInitial) {
          return isOnSplash ? null : splash;
        }

        if (authState is AuthAuthenticated) {
          return isPublic ? home : null;
        }

        // unauthenticated
        return isPublic ? null : login;
      },
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: scanner,
          name: 'scanner',
          builder: (context, state) => const PrescriptionScannerScreen(),
        ),
        GoRoute(
          path: ocrVerification,
          name: 'ocr-verification',
          builder: (context, state) => const OcrVerificationScreen(),
        ),
        GoRoute(
          path: notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: reminders,
          name: 'reminders',
          builder: (context, state) => const RemindersScreen(),
        ),
        GoRoute(
          path: reminderDetail,
          name: 'reminder-detail',
          builder: (context, state) => ReminderDetailScreen(
            model: state.extra as PrescriptionReminderModel,
          ),
        ),
        GoRoute(
          path: vault,
          name: 'vault',
          builder: (context, state) => const HealthVaultScreen(),
        ),
        GoRoute(
          path: qrCard,
          name: 'qr-card',
          builder: (context, state) => const EmergencyQrScreen(),
        ),
        GoRoute(
          path: chatbot,
          name: 'chatbot',
          builder: (context, state) => const ChatbotScreen(),
        ),
        GoRoute(
          path: alarm,
          name: 'alarm',
          builder: (context, state) {
            final payload = state.extra as Map<String, dynamic>;
            return AlarmScreen(payload: payload);
          },
        ),
      ],
    );
  }
}

// Helper for GoRouter to listen to BLoC stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
