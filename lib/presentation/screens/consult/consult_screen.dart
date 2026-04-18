import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event_state.dart';
import '../../blocs/family/active_profile_cubit.dart';
import '../../blocs/recording/recording_bloc.dart';
import '../../blocs/recording/recording_event_state.dart';
import '../../../data/models/saved_recording_model.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentlyPlayingId;

  String? _userId;

  Timer? _timer;
  int _recordSeconds = 0;
  
  late AnimationController _waveController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
        
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) setState(() => _currentlyPlayingId = null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      final newId = context.watch<ActiveProfileCubit>().getCompositeUserId(baseId, baseName);
      if (_userId != newId) {
        _userId = newId;
        context.read<RecordingBloc>().add(LoadRecordings(_userId!));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        if (_isPaused) {
          await _audioRecorder.resume();
          _startTimer();
          setState(() => _isPaused = false);
        } else {
          await _audioRecorder.pause();
          _stopTimer();
          setState(() => _isPaused = true);
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/consult_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          
          setState(() {
            _isRecording = true;
            _isPaused = false;
            _recordSeconds = 0;
          });
          _startTimer();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _stopRecordingAndSave(BuildContext context) async {
    _stopTimer();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (path != null && mounted) {
       _showSaveDialog(context, path, _recordSeconds);
    }
  }

  void _showSaveDialog(BuildContext context, String path, int durationSeconds) {
    final titleController = TextEditingController(text: 'Doctor Visit');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Save Recording', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              AppTextField(
                controller: titleController,
                label: 'Recording Title',
                hint: 'e.g., Follow up with Dr. Smith',
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save',
                onTap: () {
                  if (_userId != null) {
                    final recording = SavedRecordingModel(
                      id: const Uuid().v4(),
                      userId: _userId!,
                      title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'Doctor Visit',
                      filePath: path,
                      durationSeconds: durationSeconds,
                      timestamp: DateTime.now(),
                    );
                    context.read<RecordingBloc>().add(AddRecording(recording));
                    Navigator.pop(context);
                  }
                },
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePlay(SavedRecordingModel recording) async {
    if (_currentlyPlayingId == recording.id) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(recording.filePath));
      setState(() => _currentlyPlayingId = recording.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Consultation',
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
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRecordingArea(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 32),
            _buildSavedRecordings(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          'Record Consultation',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Press the microphone to start transcribing your doctor\'s advice. MedAssist will extract key instructions for you.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording ? AppColors.primary : AppColors.border,
          width: _isRecording ? 2 : 1,
        ),
        boxShadow: _isRecording ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 4,
          )
        ] : null,
      ),
      child: Column(
        children: [
          // Timer and Waveform
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_isPaused ? Icons.pause_circle_filled : Icons.fiber_manual_record, size: 12, color: _isRecording ? AppColors.error : AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_recordSeconds),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isRecording ? AppColors.error : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRecording && !_isPaused)
                SizedBox(
                  height: 30,
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(15, (index) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            width: 3,
                            height: max(4, _random.nextDouble() * 30 * _waveController.value),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Status Text
          SizedBox(
            height: 60,
            child: Center(
              child: Text(
                _isRecording 
                  ? (_isPaused ? "Recording Paused" : "Actively Recording...") 
                  : "Tap Start to begin recording visit",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _isRecording ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (_isRecording) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => _stopRecordingAndSave(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text('Finish', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.white : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isRecording ? AppColors.primary : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(
                        _isRecording ? (_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded) : Icons.mic_rounded, 
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? (_isPaused ? 'Resume' : 'Pause') : 'Start Recording',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavedRecordings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Consultations',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<RecordingBloc, RecordingState>(
          builder: (context, state) {
            if (state is RecordingLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RecordingLoaded) {
              if (state.recordings.isEmpty) {
                return Center(
                  child: Text('No saved recordings yet.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.recordings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rec = state.recordings[index];
                  final isPlaying = _currentlyPlayingId == rec.id;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _togglePlay(rec),
                          child: CircleAvatar(
                            backgroundColor: isPlaying ? AppColors.error : AppColors.primarySurface,
                            child: Icon(
                              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: isPlaying ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatTime(rec.durationSeconds)} • ${rec.timestamp.day}/${rec.timestamp.month}/${rec.timestamp.year}', 
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          onPressed: () {
                            // Safely stop playback if deleting
                            if (_currentlyPlayingId == rec.id) {
                              _audioPlayer.stop();
                              setState(() => _currentlyPlayingId = null);
                            }
                            context.read<RecordingBloc>().add(DeleteRecording(rec.id, _userId!));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
