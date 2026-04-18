import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medassist/core/constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.document_scanner_rounded,
      title: AppStrings.onboarding1Title,
      subtitle: AppStrings.onboarding1Subtitle,
      gradient: const LinearGradient(
        colors: [Color(0xFF0B8FAC), Color(0xFF065F78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF4DB6CC),
    ),
    OnboardingData(
      icon: Icons.mic_rounded,
      title: AppStrings.onboarding2Title,
      subtitle: AppStrings.onboarding2Subtitle,
      gradient: const LinearGradient(
        colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFFA29BFE),
    ),
    OnboardingData(
      icon: Icons.favorite_rounded,
      title: AppStrings.onboarding3Title,
      subtitle: AppStrings.onboarding3Subtitle,
      gradient: const LinearGradient(
        colors: [Color(0xFF00B894), Color(0xFF00776B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF55EFC4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final current = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: current.gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: _circle(180, 0.08),
              ),
              Positioned(
                bottom: 100,
                left: -60,
                child: _circle(200, 0.06),
              ),

              Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _animController.reset();
                        _animController.forward();
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPage(_pages[index], size);
                      },
                    ),
                  ),

                  // Bottom section
                  _buildBottomSection(current),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: Curves.elasticOut.transform(_animController.value),
                child: Opacity(
                  opacity: _animController.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                data.icon,
                size: 68,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _animController.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(
                      0, 20 * (1 - _animController.value.clamp(0.0, 1.0))),
                  child: child,
                ),
              );
            },
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: (_animController.value * 1.2 - 0.2).clamp(0.0, 1.0),
                child: child,
              );
            },
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(OnboardingData current) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Next / Get Started button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: current.gradient.colors.first,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage == _pages.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: current.gradient.colors.first,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
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

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color accentColor;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
  });
}
