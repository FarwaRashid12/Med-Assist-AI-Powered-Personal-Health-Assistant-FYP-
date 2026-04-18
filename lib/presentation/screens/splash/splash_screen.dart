import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:medassist/presentation/blocs/auth/auth_bloc.dart';
import 'package:medassist/presentation/blocs/auth/auth_event_state.dart';
import 'package:medassist/core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthCheckRequested());

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return;

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B8FAC), Color(0xFF065F78), Color(0xFF043D50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background circles (decorative)
            Positioned(
              top: -80,
              right: -60,
              child: _buildDecorativeCircle(220, 0.08),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildDecorativeCircle(280, 0.06),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              right: -40,
              child: _buildDecorativeCircle(120, 0.1),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container
                    AnimatedBuilder(
                      animation: _scaleAnim,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.medical_services_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      AppStrings.appTagline,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Loading indicator
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom branding
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: child,
                ),
                child: Column(
                  children: [
                    Text(
                      'Final Year Project',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
