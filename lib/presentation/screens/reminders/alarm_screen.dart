import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medassist/core/constants/app_colors.dart';
import 'package:lottie/lottie.dart';

class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initTts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0); // Ensure max volume for the alarm

    
    // Start speaking immediately
    _speakReminder();
  }

  Future<void> _speakReminder() async {
    final medicines = widget.payload['medicineNames'] as String? ?? 'your medicine';
    final message = "It's time to take your $medicines.";
    
    setState(() => _isPlaying = true);
    await _flutterTts.speak(message);
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.payload['title'] ?? 'Medication Reminder';
    final medicines = widget.payload['medicineNames'] ?? 'Medications';
    final summary = widget.payload['body'] ?? 'Time for your dose';

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Sleek Dark Mode
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Animated Icon
                  Center(
                    child: ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.1).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Text Content
                  Text(
                    "IT'S TIME",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    medicines,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),

                  // Voice Indicator
                  GestureDetector(
                    onTap: _speakReminder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? "Speaking..." : "Replay Voice",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Actions
                  Column(
                    children: [
                      _buildActionButton(
                        onTap: () => Navigator.pop(context),
                        label: "I HAVE TAKEN IT",
                        color: AppColors.primary,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        onTap: () => Navigator.pop(context),
                        label: "SNOOZE 5 MINS",
                        color: Colors.white24,
                        isPrimary: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required Color color,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isPrimary ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
