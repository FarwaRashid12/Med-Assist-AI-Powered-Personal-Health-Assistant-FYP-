import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/models/saved_prescription_model.dart';
import '../../../data/models/health_vitals_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/health/health_bloc.dart';
import '../../blocs/health/health_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event_state.dart';
import '../../../data/models/notification_model.dart';
import '../../widgets/common/app_button.dart';

/// Standardized vital types matching the AddVitalsBottomSheet.
enum _VitalType { bloodPressure, bloodSugar, heartRate, other }

const _vitalTypeLabels = {
  _VitalType.bloodPressure: 'Blood Pressure',
  _VitalType.bloodSugar:    'Blood Sugar',
  _VitalType.heartRate:     'Heart Rate',
  _VitalType.other:         'Other',
};

const _vitalTypeIcons = {
  _VitalType.bloodPressure: Icons.favorite_rounded,
  _VitalType.bloodSugar:    Icons.water_drop_rounded,
  _VitalType.heartRate:     Icons.monitor_heart_rounded,
  _VitalType.other:         Icons.add_circle_outline_rounded,
};

const _vitalTypeHints = {
  _VitalType.bloodPressure: '120/80',
  _VitalType.bloodSugar:    '100',
  _VitalType.heartRate:     '75',
  _VitalType.other:         'Enter reading',
};

const _vitalTypeUnits = {
  _VitalType.bloodPressure: 'mmHg',
  _VitalType.bloodSugar:    'mg/dL',
  _VitalType.heartRate:     'bpm',
  _VitalType.other:         '',
};

/// Holds state for a single vital entry row.
class _VitalEntry {
  _VitalType type;
  final TextEditingController valueController;
  final TextEditingController value2Controller; // diastolic for BP
  final TextEditingController customLabelController; // only used for 'other'

  _VitalEntry({this.type = _VitalType.bloodPressure})
      : valueController = TextEditingController(),
        value2Controller = TextEditingController(),
        customLabelController = TextEditingController();

  _VitalEntry.fromMap(String label, String value)
      : type = _labelToType(label),
        valueController = _parseSystolic(label, value),
        value2Controller = _parseDiastolic(label, value),
        customLabelController = TextEditingController(
          text: _labelToType(label) == _VitalType.other ? label : '');

  static _VitalType _labelToType(String label) {
    final k = label.toLowerCase();
    if (k.contains('bp') || k.contains('blood pressure') || k.contains('pressure') || k.contains('systolic') || k.contains('diastolic')) return _VitalType.bloodPressure;
    if (k.contains('sugar') || k.contains('glucose') || k.contains('bs') || k.contains('rbs') || k.contains('fbs')) return _VitalType.bloodSugar;
    if (k.contains('heart') || k.contains('hr') || k.contains('pulse') || k.contains('bpm')) return _VitalType.heartRate;
    return _VitalType.other;
  }

  /// For BP: extract systolic part; for others just use the full value.
  static TextEditingController _parseSystolic(String label, String value) {
    if (_labelToType(label) == _VitalType.bloodPressure) {
      final parts = value.trim().split(RegExp(r'[/|\-\s]+'));
      return TextEditingController(text: parts.isNotEmpty ? parts[0].trim() : value.trim());
    }
    return TextEditingController(text: value.trim());
  }

  /// For BP: extract diastolic part; empty for others.
  static TextEditingController _parseDiastolic(String label, String value) {
    if (_labelToType(label) == _VitalType.bloodPressure) {
      final parts = value.trim().split(RegExp(r'[/|\-\s]+'));
      return TextEditingController(text: parts.length >= 2 ? parts[1].trim() : '');
    }
    return TextEditingController();
  }

  /// Returns the canonical label string for persistence.
  String get canonicalLabel {
    if (type == _VitalType.other) return customLabelController.text.trim().isEmpty ? 'Other' : customLabelController.text.trim();
    return _vitalTypeLabels[type]!;
  }

  /// Returns the string value for storage (BP combines both fields).
  String get canonicalValue {
    if (type == _VitalType.bloodPressure) {
      final sys = valueController.text.trim();
      final dia = value2Controller.text.trim();
      if (sys.isNotEmpty && dia.isNotEmpty) return '$sys/$dia';
      return sys;
    }
    return valueController.text.trim();
  }

  void dispose() {
    valueController.dispose();
    value2Controller.dispose();
    customLabelController.dispose();
  }
}

class OcrVerificationScreen extends StatefulWidget {
  const OcrVerificationScreen({super.key});

  @override
  State<OcrVerificationScreen> createState() => _OcrVerificationScreenState();
}

class _OcrVerificationScreenState extends State<OcrVerificationScreen> {
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<_MedicineControllers> _medicineControllers = [];
  final List<_VitalEntry> _vitalEntries = [];
  bool _hasInitialized = false;
  File? _audioFileFromState;
  File? _imageFileFromState;

  void _initializeFromModel(PrescriptionModel model, File imageFile, File? audioFile, Map<String, String>? vitals) {
    if (_hasInitialized) return;
    _hasInitialized = true;
    _audioFileFromState = audioFile;
    _imageFileFromState = imageFile;

    _clinicController.text = model.clinicName;
    _doctorController.text = model.doctorName;
    _notesController.text = model.notes;

    // Initialize Vitals with standardized types
    _vitalEntries.clear();
    if (vitals != null) {
      vitals.forEach((key, value) {
        _vitalEntries.add(_VitalEntry.fromMap(key, value));
      });
    }

    _medicineControllers.clear();
    for (final med in model.medicines) {
      _medicineControllers.add(_MedicineControllers(
        name: TextEditingController(text: med.name),
        dosage: TextEditingController(text: med.dosage),
        frequency: TextEditingController(text: med.frequency),
        durationDays: TextEditingController(text: med.durationDays),
        whenToTake: TextEditingController(text: med.whenToTake),
        confidence: med.confidence,
      ));
    }
  }

  void _addVitalRow() {
    setState(() => _vitalEntries.add(_VitalEntry()));
  }

  void _removeVitalRow(int index) {
    setState(() {
      _vitalEntries[index].dispose();
      _vitalEntries.removeAt(index);
    });
  }

  void _addEmptyMedicine() {
    setState(() {
      _medicineControllers.add(_MedicineControllers(
        name: TextEditingController(),
        dosage: TextEditingController(),
        frequency: TextEditingController(),
        durationDays: TextEditingController(),
        whenToTake: TextEditingController(),
        confidence: 100, // Manual entries are verified
      ));
    });
  }

  bool get _hasAllRequired {
    if (_clinicController.text.trim().isEmpty) return false;
    if (_doctorController.text.trim().isEmpty) return false;
    for (final mc in _medicineControllers) {
      if (mc.frequency.text.trim().isEmpty) return false;
      if (mc.durationDays.text.trim().isEmpty) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _clinicController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    for (final ve in _vitalEntries) {
      ve.dispose();
    }
    for (final mc in _medicineControllers) {
      mc.dispose();
    }
    super.dispose();
  }

  Color _confidenceColor(int c) {
    if (c >= 85) return AppColors.success;
    if (c >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _confidenceLabel(int c) {
    if (c >= 85) return 'High';
    if (c >= 60) return 'Medium';
    return 'Low';
  }

  Future<void> _savePrescription() async {
    // Check required fields
    if (!_hasAllRequired) {
      if (_clinicController.text.trim().isEmpty || _doctorController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both the Clinic Name and Doctor Name before saving.'), backgroundColor: AppColors.warning),
        );
        return;
      }

      final missingFreq = _medicineControllers.any((m) => m.frequency.text.trim().isEmpty);
      final missingDur  = _medicineControllers.any((m) => m.durationDays.text.trim().isEmpty);
      String msg = '';
      if (missingFreq && missingDur) {
        msg = 'Please enter the frequency and duration for all medicines before saving.';
      } else if (missingFreq) {
        msg = 'Please enter the frequency for all medicines before saving.';
      } else {
        msg = 'Please enter the duration (number of days) for all medicines before saving.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
      );
      return;
    }

    String? baseUserId;
    String? primaryUserName;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      baseUserId = authState.user.id;
      primaryUserName = authState.user.fullName;
    } else if (authState is AuthRegisterSuccess) {
      baseUserId = authState.user.id;
      primaryUserName = authState.user.fullName;
    }

    String finalUserId = baseUserId ?? 'guest';
    if (baseUserId != null && primaryUserName != null) {
      finalUserId = context.read<ActiveProfileCubit>().getCompositeUserId(baseUserId, primaryUserName);
    }

    // Collect vitals from typed entries
    final Map<String, String> finalVitals = {};
    for (final entry in _vitalEntries) {
      final val = entry.canonicalValue;
      if (val.isNotEmpty) {
        finalVitals[entry.canonicalLabel] = val;
      }
    }

    // Generate ID first so we can use it for media filenames
    final prescriptionId = const Uuid().v4();

    // Persist media files to permanent storage
    String? savedImagePath;
    String? savedAudioPath;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docsDir.path}/prescriptions/media');
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

      // Copy image to permanent location
      final imageFile = _imageFileFromState;
      if (imageFile != null && await imageFile.exists()) {
        final ext = p.extension(imageFile.path);
        final dest = '${mediaDir.path}/${prescriptionId}_image$ext';
        await imageFile.copy(dest);
        savedImagePath = dest;
      }

      // Copy audio to permanent location
      if (_audioFileFromState != null && await _audioFileFromState!.exists()) {
        final ext = p.extension(_audioFileFromState!.path);
        final dest = '${mediaDir.path}/${prescriptionId}_audio$ext';
        await _audioFileFromState!.copy(dest);
        savedAudioPath = dest;
      }
    } catch (_) {}

    final saved = SavedPrescriptionModel(
      id: prescriptionId,
      userId: finalUserId,
      clinicName: _clinicController.text,
      doctorName: _doctorController.text,
      medicineNames: _medicineControllers.map((m) => m.name.text).toList(),
      medicineDosages: _medicineControllers.map((m) => m.dosage.text).toList(),
      medicineFrequencies: _medicineControllers.map((m) => m.frequency.text).toList(),
      medicineTimings: _medicineControllers.map((m) => m.whenToTake.text).toList(),
      medicineDurations: _medicineControllers.map((m) => m.durationDays.text).toList(),
      notes: _notesController.text,
      vitals: finalVitals,
      savedAt: DateTime.now(),
      imagePath: savedImagePath,
      audioPath: savedAudioPath,
    );

    // ── Extract & save vitals NOW (sync, before navigation) ──────────────
    // IMPORTANT: We must do this BEFORE dispatching SavePrescriptionRequested
    // because PrescriptionSaved → context.go('/home') disposes this widget,
    // making any context.read() after the 600ms delay silently fail.
    if (finalVitals.isNotEmpty) {
      int? systolic;
      int? diastolic;
      double? bloodSugar;
      int? heartRate;

      finalVitals.forEach((key, value) {
        final k = key.toLowerCase();
        final v = value.trim();

        if (k.contains('blood pressure') || k.contains('bp') || k.contains('pressure')) {
          final parts = v.split(RegExp(r'[/|\-\s]+'));
          if (parts.length >= 2) {
            systolic = int.tryParse(parts[0].trim());
            diastolic = int.tryParse(parts[1].trim());
          }
        } else if (k.contains('blood sugar') || k.contains('glucose') || k.contains('sugar')) {
          bloodSugar = double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
        } else if (k.contains('heart rate') || k.contains('pulse') || k.contains('bpm')) {
          heartRate = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
        }
      });

      if (systolic != null || diastolic != null || bloodSugar != null || heartRate != null) {
        final vitalsModel = HealthVitalsModel(
          id: const Uuid().v4(),
          userId: finalUserId,
          systolic: systolic ?? 0,
          diastolic: diastolic ?? 0,
          bloodSugar: bloodSugar ?? 0.0,
          heartRate: heartRate ?? 0,
          timestamp: DateTime.now(),
        );
        // Safe — context is still alive at this point
        context.read<HealthBloc>().add(AddHealthVitals(vitalsModel));
      }
    }

    // ── Save the Prescription (triggers navigation on PrescriptionSaved) ──
    context.read<PrescriptionBloc>().add(SavePrescriptionRequested(saved));

    // ── Generate System Notification ──
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: finalUserId,
      title: 'Prescription Saved',
      body: 'Prescription from ${saved.clinicName} was saved to your Vault.',
      type: 'Vault',
      timestamp: DateTime.now(),
    );
    context.read<NotificationBloc>().add(AddNotification(notification));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Verify Prescription',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is PrescriptionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Prescription saved to your Health Vault!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<PrescriptionBloc>().add(const ResetPrescription());
            context.go('/home');
          }
        },
        buildWhen: (prev, curr) => curr is! PrescriptionSaved,
        builder: (context, state) {
          if (state is PrescriptionAnalyzing) return _buildLoading(state.imageFile);
          if (state is PrescriptionSuccess) {
            _initializeFromModel(state.prescription, state.imageFile, state.audioFile, state.vitals);
            return _buildForm(state.imageFile);
          }
          if (state is PrescriptionError) return _buildError(state.message);
          return Center(child: Text('Select a prescription image to analyze.', style: GoogleFonts.inter(color: AppColors.textSecondary)));
        },
      ),
    );
  }

  Widget _buildLoading(File imageFile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.hardEdge,
              child: Image.file(imageFile, fit: BoxFit.cover),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Analyzing Prescription...', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('AI is reading your prescription. This may take a few seconds.',
                textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 20),
            Text('Analysis Failed', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            AppButton(
              label: 'Go Back', icon: Icons.arrow_back_rounded,
              onTap: () { context.read<PrescriptionBloc>().add(const ResetPrescription()); context.pop(); },
              gradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(File imageFile) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          Container(
            height: 130,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            clipBehavior: Clip.hardEdge,
            child: Image.file(imageFile, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),

          // Prescription header
          Text('Prescription Details', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Review and edit before saving.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField('Clinic', _clinicController, Icons.local_hospital_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Doctor', _doctorController, Icons.person_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notes section
          Text('Consultation Notes', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Any specific advice or instructions from the doctor...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // Missing required fields warning
          if (_medicineControllers.any((m) => m.frequency.text.trim().isEmpty || m.durationDays.text.trim().isEmpty))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(builder: (context) {
                      final mf = _medicineControllers.where((m) => m.frequency.text.trim().isEmpty).length;
                      final md = _medicineControllers.where((m) => m.durationDays.text.trim().isEmpty).length;
                      String msg = '';
                      if (mf > 0 && md > 0) {
                        msg = '$mf medicine(s) missing frequency and $md missing duration. Fill them to enable reminders.';
                      } else if (mf > 0) {
                        msg = '$mf medicine(s) missing frequency. Please enter the frequency to set reminders.';
                      } else {
                        msg = '$md medicine(s) missing duration. Please enter how many days to take it.';
                      }
                      return Text(msg,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600));
                    }),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Vitals section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Encounter Vitals', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (_vitalEntries.isEmpty)
                Text('None found', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 12),
          ..._vitalEntries.asMap().entries.map((e) => _buildVitalEntryRow(e.key)),
          
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addVitalRow,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.secondary),
              label: Text('Add Vital Reading', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.secondary)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),

          const SizedBox(height: 24),

          // Medicines header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medicines', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('${_medicineControllers.length} found', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),

          // Medicine cards
          ...List.generate(_medicineControllers.length, (i) => _buildMedicineCard(i)),
          
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addEmptyMedicine,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text('Add Extra Medicine', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Save button
          AppButton(
            label: 'Save Prescription',
            icon: Icons.save_rounded,
            onTap: _savePrescription,
            gradient: AppColors.primaryGradient,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(int index) {
    final mc = _medicineControllers[index];
    final confColor = _confidenceColor(mc.confidence);
    final confLabel = _confidenceLabel(mc.confidence);
    final freqMissing = mc.frequency.text.trim().isEmpty;
    final durMissing  = mc.durationDays.text.trim().isEmpty;
    final anyMissing  = freqMissing || durMissing;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: anyMissing ? AppColors.warning : AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with index + name + confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                child: Text('#${index + 1}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(mc.name.text, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: confColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: confColor, size: 14),
                    const SizedBox(width: 4),
                    Text('${mc.confidence}% $confLabel', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: confColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Medicine Name
          _buildField('Medicine Name', mc.name, Icons.medication_rounded),
          const SizedBox(height: 10),

          // Dosage + Frequency row
          Row(
            children: [
              Expanded(child: _buildField('Dosage', mc.dosage, Icons.scale_rounded)),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  freqMissing ? 'Frequency *' : 'Frequency',
                  mc.frequency,
                  Icons.schedule_rounded,
                  isRequired: freqMissing,
                  hintText: freqMissing ? 'e.g. 1+1' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Duration + When to take row
          Row(
            children: [
              Expanded(
                child: _buildField(
                  durMissing ? 'Duration *' : 'Duration',
                  mc.durationDays,
                  Icons.calendar_today_rounded,
                  isRequired: durMissing,
                  hintText: durMissing ? 'e.g. 7 days' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  'When to Take',
                  mc.whenToTake,
                  Icons.restaurant_rounded,
                  hintText: mc.whenToTake.text.isEmpty ? 'e.g. After meals' : null,
                ),
              ),
            ],
          ),

          // Quick set chips
          if (freqMissing) ...[
            const SizedBox(height: 12),
            Text('Quick Set Frequency:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('1+0+0\nOnce Daily', mc.frequency),
                _buildQuickChip('1+1\nMorning + Evening', mc.frequency),
                _buildQuickChip('1+1+1\nThree Times', mc.frequency),
                _buildQuickChip('0+0+1\nBedtime Only', mc.frequency),
                _buildQuickChip('SOS\nWhen Needed', mc.frequency),
              ],
            ),
          ],
          if (durMissing) ...[
            const SizedBox(height: 12),
            Text('Quick Set Duration:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationChip('3 days', mc.durationDays),
                _buildDurationChip('5 days', mc.durationDays),
                _buildDurationChip('7 days', mc.durationDays),
                _buildDurationChip('10 days', mc.durationDays),
                _buildDurationChip('14 days', mc.durationDays),
                _buildDurationChip('1 month', mc.durationDays),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, TextEditingController controller) {
    final parts = label.split('\n');
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.text = '${parts[0]} (${parts[1]})';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(parts[0], style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text(parts[1], style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.text = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalEntryRow(int index) {
    final entry = _vitalEntries[index];
    final type = entry.type;
    final color = _vitalTypeIcons.keys.contains(type) ? _colorForType(type) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector row
          Row(
            children: [
              Icon(_vitalTypeIcons[type], color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_VitalType>(
                    value: type,
                    isDense: true,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    items: _VitalType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_vitalTypeLabels[t]!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => entry.type = val);
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeVitalRow(index),
                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Custom label for 'other'
          if (type == _VitalType.other) ...[
            TextField(
              controller: entry.customLabelController,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Vital Name',
                hintText: 'e.g. Temperature, Weight …',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
                filled: true, fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Value field — BP gets two separate numeric fields
          if (type == _VitalType.bloodPressure) ...[  
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.valueController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '120',
                      labelText: 'Systolic',
                      hintStyle: GoogleFonts.outfit(fontSize: 18, color: AppColors.textHint),
                      suffixText: 'mmHg',
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      filled: true, fillColor: color.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('/', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w300, color: AppColors.textHint)),
                ),
                Expanded(
                  child: TextField(
                    controller: entry.value2Controller,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '80',
                      labelText: 'Diastolic',
                      hintStyle: GoogleFonts.outfit(fontSize: 18, color: AppColors.textHint),
                      suffixText: 'mmHg',
                      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      filled: true, fillColor: color.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
          ] else TextField(
            controller: entry.valueController,
            keyboardType: type == _VitalType.bloodSugar
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _vitalTypeHints[type] ?? 'Enter reading',
              hintStyle: GoogleFonts.outfit(fontSize: 18, color: AppColors.textHint),
              suffixText: _vitalTypeUnits[type] ?? '',
              suffixStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              filled: true, fillColor: color.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForType(_VitalType t) {
    switch (t) {
      case _VitalType.bloodPressure: return const Color(0xFFE53935);
      case _VitalType.bloodSugar:    return AppColors.accent;
      case _VitalType.heartRate:     return AppColors.secondary;
      case _VitalType.other:         return AppColors.primary;
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isRequired = false, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isRequired ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isRequired ? AppColors.warning : AppColors.textHint, size: 18),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
            filled: true,
            fillColor: isRequired ? AppColors.warning.withValues(alpha: 0.05) : AppColors.surfaceVariant,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isRequired ? BorderSide(color: AppColors.warning.withValues(alpha: 0.5)) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isRequired ? BorderSide(color: AppColors.warning.withValues(alpha: 0.5)) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isRequired ? AppColors.warning : AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineControllers {
  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController frequency;
  final TextEditingController durationDays;
  final TextEditingController whenToTake;
  final int confidence;

  _MedicineControllers({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    required this.whenToTake,
    required this.confidence,
  });

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    durationDays.dispose();
    whenToTake.dispose();
  }
}
