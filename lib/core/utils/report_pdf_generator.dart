import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../data/models/health_vitals_model.dart';
import '../../data/models/saved_prescription_model.dart';

class ReportPdfGenerator {
  static Future<void> generateAndPrintSReport({
    required String patientName,
    required List<HealthVitalsModel> vitals,
    required List<SavedPrescriptionModel> prescriptions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(patientName),
          pw.SizedBox(height: 20),
          _buildVitalsSummary(vitals),
          pw.SizedBox(height: 30),
          _buildPrescriptionsSummary(prescriptions),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MedAssist_Report_$patientName',
    );
  }

  static pw.Widget _buildHeader(String patientName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MedAssist Health Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Patient Name: $patientName', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Generated On: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildVitalsSummary(List<HealthVitalsModel> vitals) {
    if (vitals.isEmpty) {
      return pw.Text('No health vitals logged.', style: pw.TextStyle(color: PdfColors.grey));
    }

    // Sort by most recent
    vitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final displayVitals = vitals.take(15).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recent Vitals Logs', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Date', 'BP (mmHg)', 'Sugar (mg/dL)', 'Heart Rate (bpm)'],
          data: displayVitals.map((v) => [
            DateFormat('MM/dd/yy hh:mm a').format(v.timestamp),
            '${v.systolic}/${v.diastolic}',
            v.bloodSugar.toString(),
            v.heartRate.toString(),
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }

  static pw.Widget _buildPrescriptionsSummary(List<SavedPrescriptionModel> prescriptions) {
    if (prescriptions.isEmpty) {
      return pw.Text('No prescriptions found in Medical Vault.', style: pw.TextStyle(color: PdfColors.grey));
    }

    prescriptions.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Saved Prescriptions History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...prescriptions.map((p) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${p.doctorName} - ${p.clinicName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('Date Scanned: ${DateFormat('MMM dd, yyyy').format(p.savedAt)}', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                pw.SizedBox(height: 6),
                pw.Text('Medicines prescribed:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 4),
                ...List.generate(p.medicineNames.length, (i) {
                  return pw.Text('• ${p.medicineNames[i]} - ${p.medicineDosages.length > i ? p.medicineDosages[i] : ''} (${p.medicineFrequencies.length > i ? p.medicineFrequencies[i] : ''})', style: const pw.TextStyle(fontSize: 11));
                }),
                if (p.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text('Notes: ${p.notes}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
                ]
              ],
            ),
          );
        }),
      ],
    );
  }
}
