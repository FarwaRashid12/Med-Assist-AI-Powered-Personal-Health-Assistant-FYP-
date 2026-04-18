import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/prescription/prescription_bloc.dart';
import '../../blocs/prescription/prescription_event_state.dart';
import '../../blocs/recording/recording_bloc.dart';
import '../../blocs/recording/recording_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../../data/models/saved_recording_model.dart';
import '../../widgets/common/app_button.dart';

class PrescriptionScannerScreen extends StatefulWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  State<PrescriptionScannerScreen> createState() =>
      _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState extends State<PrescriptionScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _imageFile;
  File? _audioFile;

  final List<Map<String, TextEditingController>> _vitalsControllers = [
    {'label': TextEditingController(), 'value': TextEditingController()},
    {'label': TextEditingController(), 'value': TextEditingController()},
  ];

  @override
  void dispose() {
    for (var v in _vitalsControllers) {
      v['label']?.dispose();
      v['value']?.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (!status.isGranted) status = await Permission.camera.request();

        if (status.isPermanentlyDenied && mounted) {
          _showPermissionDialog('Camera');
          return;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedFile != null && mounted) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access image. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAudioSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Audio Source', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _showVaultRecordingsSheet();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
              ),
              title: Text('MedAssist Vault', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Pick a consultation recorded natively', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickAudioFromDevice();
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.secondarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.folder_open_rounded, color: AppColors.secondary),
              ),
              title: Text('Upload from Device', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Pick an .mp3 or .m4a file', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVaultRecordingsSheet() {
    final auth = context.read<AuthBloc>().state;
    String? baseId;
    String? baseName;
    if (auth is AuthAuthenticated) {
      baseId = auth.user.id;
      baseName = auth.user.fullName;
    } else if (auth is AuthRegisterSuccess) {
      baseId = auth.user.id;
      baseName = auth.user.fullName;
    }
    
    if (baseId != null && baseName != null) {
      final compositeId = context.read<ActiveProfileCubit>().getCompositeUserId(baseId, baseName);
      context.read<RecordingBloc>().add(LoadRecordings(compositeId));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Vault Consultations', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<RecordingBloc, RecordingState>(
                  builder: (context, state) {
                    if (state is RecordingLoading) return const Center(child: CircularProgressIndicator());
                    if (state is RecordingLoaded) {
                      if (state.recordings.isEmpty) {
                        return Center(child: Text('No saved consultations found in vault.', style: GoogleFonts.inter(color: AppColors.textSecondary)));
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: state.recordings.length,
                        separatorBuilder: (_,__) => const Divider(),
                        itemBuilder: (context, index) {
                          final rec = state.recordings[index];
                          return ListTile(
                            onTap: () {
                              setState(() => _audioFile = File(rec.filePath));
                              Navigator.pop(context);
                            },
                            leading: const Icon(Icons.audio_file_rounded, color: AppColors.primary, size: 32),
                            title: Text(rec.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            subtitle: Text('${rec.timestamp.day}/${rec.timestamp.month}/${rec.timestamp.year} • ${(rec.durationSeconds ~/ 60).toString().padLeft(2,'0')}:${(rec.durationSeconds % 60).toString().padLeft(2,'0')}', style: GoogleFonts.inter(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAudioFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      );

      if (result != null && result.files.single.path != null && mounted) {
        setState(() => _audioFile = File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pick audio file.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName access has been permanently denied. Please go to Settings and enable it manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _addVitalRow() {
    if (_vitalsControllers.length >= 5) return;
    setState(() {
      _vitalsControllers.add({
        'label': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _submitVisit() {
    if (_imageFile == null) return;

    final Map<String, String> parsedVitals = {};
    for (var ctrl in _vitalsControllers) {
      final key = ctrl['label']!.text.trim();
      final val = ctrl['value']!.text.trim();
      if (key.isNotEmpty && val.isNotEmpty) {
        parsedVitals[key] = val;
      }
    }

    context.read<PrescriptionBloc>().add(AnalyzePrescriptionRequested(
          _imageFile!,
          audioFile: _audioFile,
          vitals: parsedVitals.isNotEmpty ? parsedVitals : null,
        ));

    // Jump to verification screen where the BlocListener will handle loading
    context.push('/ocr-verification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('New Visit',
            style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. PRESCRIPTION IMAGE --- //
              _buildSectionHeader('1. Prescription', isRequired: true),
              const SizedBox(height: 12),
              if (_imageFile == null)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.camera_alt_rounded,
                        label: 'Take Photo',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ]
                )
              else
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _imageFile = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // --- 2. AUDIO RECORDING --- //
              _buildSectionHeader('2. Doctor\'s Recording'),
              const SizedBox(height: 8),
              Text(
                'Upload an audio recording of your consultation. Our AI will automatically synthesize notes and fill in missing prescription details.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (_audioFile == null)
                GestureDetector(
                  onTap: _showAudioSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mic_rounded,
                            color: AppColors.secondary),
                        const SizedBox(width: 10),
                        Text('Upload Audio File',
                            style: GoogleFonts.inter(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file_rounded,
                          color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _audioFile!.path.split('/').last,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _audioFile = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // --- 3. VITALS --- //
              _buildSectionHeader('3. Encounter Vitals'),
              const SizedBox(height: 12),
              ...List.generate(_vitalsControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildVitalField(
                            _vitalsControllers[index]['label']!,
                            'Label (e.g. BP)'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildVitalField(
                            _vitalsControllers[index]['value']!,
                            'Reading (e.g. 120/80)'),
                      ),
                    ],
                  ),
                );
              }),
              if (_vitalsControllers.length < 5)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addVitalRow,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 18),
                    label: const Text('Add Vital'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                  ),
                ),

              const SizedBox(height: 50),
              
              // --- ANALYZE BUTTON --- //
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _imageFile != null ? _submitVisit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Analyze Visit',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        if (isRequired) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Required',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          )
        ] else ...[
          const SizedBox(width: 8),
          Text('(Optional)',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint)),
        ]
      ],
    );
  }

  Widget _buildActionTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
