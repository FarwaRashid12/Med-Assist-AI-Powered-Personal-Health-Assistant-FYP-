import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class EmergencyQrScreen extends StatelessWidget {
  const EmergencyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Emergency QR Card',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'EMERGENCY MEDICAL CARD',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Mock
                  Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: CustomPaint(
                      painter: _QrMockPainter(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to view emergency details',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Patient Info
                  _buildInfoRow('Name', 'Muhammad Ali'),
                  _buildInfoRow('Blood Group', 'O+'),
                  _buildInfoRow('Emergency Contact', '+92 300 1234567'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Medications
            _buildDetailCard(
              title: 'Active Medications',
              icon: Icons.medication_rounded,
              color: AppColors.primary,
              items: ['Amoxicillin 500mg (3x daily)', 'Metformin 250mg (2x daily)', 'Vitamin D 1000 IU (1x daily)'],
            ),
            const SizedBox(height: 16),

            // Known Allergies
            _buildDetailCard(
              title: 'Known Allergies',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              items: ['Penicillin', 'Sulfa drugs'],
            ),
            const SizedBox(height: 16),

            // Adherence Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Weekly Adherence',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAdherenceGraph(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share Button
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Card saved to gallery!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save & Share QR Card',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdherenceGraph() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [1.0, 0.75, 1.0, 0.5, 1.0, 0.85, 0.0]; // 0 = not done yet

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        return Column(
          children: [
            SizedBox(
              height: 60,
              width: 20,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 16,
                  height: values[index] * 60,
                  decoration: BoxDecoration(
                    color: values[index] >= 0.8
                        ? AppColors.accent
                        : values[index] >= 0.5
                            ? AppColors.warning
                            : AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _QrMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 15;
    // Corners
    _drawCorner(canvas, paint, 0, 0, cellSize);
    _drawCorner(canvas, paint, size.width - cellSize * 5, 0, cellSize);
    _drawCorner(canvas, paint, 0, size.height - cellSize * 5, cellSize);

    // Random middle fill
    final rng = [
      [4, 1], [5, 3], [6, 2], [7, 4], [8, 1], [9, 3],
      [4, 5], [5, 6], [6, 7], [7, 8], [8, 5], [9, 6],
      [4, 9], [5, 10], [6, 11], [7, 9], [8, 10], [9, 11],
      [10, 4], [11, 5], [12, 6], [10, 8], [11, 9], [12, 10],
    ];
    for (final pos in rng) {
      canvas.drawRect(
        Rect.fromLTWH(pos[0] * cellSize, pos[1] * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  void _drawCorner(Canvas canvas, Paint paint, double x, double y, double cell) {
    // Outer border
    canvas.drawRect(Rect.fromLTWH(x, y, cell * 5, cell * 5), paint);
    // White inner
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cell, y + cell, cell * 3, cell * 3), whitePaint);
    // Inner square
    canvas.drawRect(Rect.fromLTWH(x + cell * 1.5, y + cell * 1.5, cell * 2, cell * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
