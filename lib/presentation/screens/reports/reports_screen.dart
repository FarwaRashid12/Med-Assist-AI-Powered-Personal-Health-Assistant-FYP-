import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/report_pdf_generator.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/health/health_bloc.dart';
import '../../blocs/health/health_event_state.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _chartFilter = 0; // 0=BP, 1=Sugar, 2=Heart Rate

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Patient';
    if (authState is AuthAuthenticated) userName = authState.user.fullName;
    if (authState is AuthRegisterSuccess) userName = authState.user.fullName;

    final activeProfileName = context.watch<ActiveProfileCubit>().state;
    final displayProfileName = activeProfileName.isEmpty ? userName : activeProfileName;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generatePdf(context, displayProfileName),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: Text('Export Report', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Analytics Overview',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your long-term health metrics and history.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),
            _buildChartFilterSegments(),
            const SizedBox(height: 20),
            _buildVitalsChart(),
            const SizedBox(height: 30),
            _buildSummaryCards(),
          ],
        ),
      ),
    );
  }

  void _generatePdf(BuildContext context, String patientName) {
    final healthState = context.read<HealthBloc>().state;
    final rxState = context.read<PrescriptionBloc>().state;

    ReportPdfGenerator.generateAndPrintSReport(
      patientName: patientName,
      vitals: healthState is HealthLoaded ? healthState.vitals : [],
      prescriptions: rxState is SavedPrescriptionsLoaded ? rxState.prescriptions : [],
    );
  }

  Widget _buildChartFilterSegments() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterTab(0, 'Blood Pressure'),
          _buildFilterTab(1, 'Sugar'),
          _buildFilterTab(2, 'Heart Rate'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _chartFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _chartFilter = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsChart() {
    return BlocBuilder<HealthBloc, HealthState>(
      builder: (context, state) {
        if (state is HealthLoading) {
           return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is HealthLoaded) {
           final vitals = List.from(state.vitals)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
           if (vitals.isEmpty) {
             return _buildEmptyState('No health vitals to graph yet.');
           }

           List<FlSpot> spots1 = [];
           List<FlSpot> spots2 = []; // For diastolic

           double minY = double.infinity;
           double maxY = 0;

           for (int i = 0; i < vitals.length; i++) {
             final v = vitals[i] as dynamic; // HealthVitalsModel
             if (_chartFilter == 0) {
               // BP
               if (v.systolic > 0 && v.diastolic > 0) {
                 spots1.add(FlSpot(i.toDouble(), v.systolic.toDouble()));
                 spots2.add(FlSpot(i.toDouble(), v.diastolic.toDouble()));
                 if (v.systolic > maxY) maxY = v.systolic.toDouble();
                 if (v.diastolic < minY) minY = v.diastolic.toDouble();
               }
             } else if (_chartFilter == 1) {
               if (v.bloodSugar > 0) {
                  spots1.add(FlSpot(i.toDouble(), v.bloodSugar));
                  if (v.bloodSugar > maxY) maxY = v.bloodSugar;
                  if (v.bloodSugar < minY) minY = v.bloodSugar;
               }
             } else {
               if (v.heartRate > 0) {
                 spots1.add(FlSpot(i.toDouble(), v.heartRate.toDouble()));
                 if (v.heartRate > maxY) maxY = v.heartRate.toDouble();
                 if (v.heartRate < minY) minY = v.heartRate.toDouble();
               }
             }
           }

           if (spots1.isEmpty) return _buildEmptyState('Not enough data to graph this metric.');

           // Buffer Y axis
           minY = (minY - 20).clamp(0, double.infinity);
           maxY = (maxY + 20);

           return Container(
             height: 260,
             padding: const EdgeInsets.only(right: 16, top: 16, bottom: 10),
             decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
             ),
             child: LineChart(
               LineChartData(
                 minY: minY,
                 maxY: maxY,
                 minX: 0,
                 maxX: (spots1.length - 1).toDouble() > 0 ? (spots1.length - 1).toDouble() : 1,
                 gridData: FlGridData(
                   show: true,
                   drawVerticalLine: false,
                   getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                 ),
                 titlesData: FlTitlesData(
                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide unreadable dates
                   leftTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: 40,
                       getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary));
                       }
                     ),
                   ),
                 ),
                 borderData: FlBorderData(show: false),
                 lineBarsData: [
                   LineChartBarData(
                     spots: spots1,
                     isCurved: true,
                     color: AppColors.primary,
                     barWidth: 3,
                     isStrokeCapRound: true,
                     dotData: FlDotData(show: true),
                     belowBarData: BarAreaData(
                       show: true,
                       color: AppColors.primary.withOpacity(0.1),
                     ),
                   ),
                   if (_chartFilter == 0) // Add diastolic line if BP
                     LineChartBarData(
                       spots: spots2,
                       isCurved: true,
                       color: Colors.blue[300]!,
                       barWidth: 3,
                       isStrokeCapRound: true,
                       dotData: FlDotData(show: true),
                     ),
                 ],
               ),
             ),
           );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
            builder: (context, state) {
              int count = 0;
              if (state is SavedPrescriptionsLoaded) count = state.prescriptions.length;
              return _buildStatCard(Icons.document_scanner_rounded, 'Prescriptions\nVault', count.toString(), Colors.purple);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: BlocBuilder<HealthBloc, HealthState>(
            builder: (context, state) {
              int count = 0;
              if (state is HealthLoaded) count = state.vitals.length;
              return _buildStatCard(Icons.monitor_heart_rounded, 'Vital\nLogs', count.toString(), Colors.orange);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
             child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text(msg, style: GoogleFonts.inter(color: AppColors.textPrimary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
