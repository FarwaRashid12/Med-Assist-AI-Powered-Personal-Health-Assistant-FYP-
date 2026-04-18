import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../data/repositories/consultation_repository.dart';
import 'consultation_event_state.dart';

class ConsultationBloc extends Bloc<ConsultationEvent, ConsultationState> {
  final ConsultationRepository _repository;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSttInitialized = false;

  ConsultationBloc(this._repository) : super(const ConsultationInitial()) {
    on<StartRecordingRequested>(_onStartRecording);
    on<UpdateTranscriptEvent>(_onUpdateTranscript);
    on<StopRecordingRequested>(_onStopRecording);
    on<ProcessConsultationRequested>(_onProcessConsultation);
  }

  Future<void> _onStartRecording(
    StartRecordingRequested event,
    Emitter<ConsultationState> emit,
  ) async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      emit(const ConsultationError('Microphone permission is required to record consultations.'));
      return;
    }

    if (!_isSttInitialized) {
      _isSttInitialized = await _speechToText.initialize(
        onError: (val) => add(UpdateTranscriptEvent('Error: \${val.errorMsg}', isFinal: true)),
        onStatus: (val) {
          if (val == 'done') {
            add(const StopRecordingRequested());
          }
        },
      );
    }

    if (_isSttInitialized) {
      emit(const ConsultationRecording('...Listening...'));
      _speechToText.listen(
        onResult: (val) {
          add(UpdateTranscriptEvent(val.recognizedWords));
        },
        listenFor: const Duration(minutes: 5), // extended for doctor visit
        pauseFor: const Duration(seconds: 10), // only stop if silent for 10s
        partialResults: true,
      );
    } else {
      emit(const ConsultationError('Failed to initialize local Speech-to-Text device engine.'));
    }
  }

  void _onUpdateTranscript(
    UpdateTranscriptEvent event,
    Emitter<ConsultationState> emit,
  ) {
    if (state is ConsultationRecording) {
      emit(ConsultationRecording(event.partialTranscript));
    }
  }

  Future<void> _onStopRecording(
    StopRecordingRequested event,
    Emitter<ConsultationState> emit,
  ) async {
    if (state is ConsultationRecording) {
      final finalWords = (state as ConsultationRecording).transcript;
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      
      if (finalWords == '...Listening...' || finalWords.trim().isEmpty) {
        emit(const ConsultationInitial());
      } else {
        // Automatically process once stopped, or leave in recording mode so user can trigger process.
        // We will just leave it in the final recording state.
        emit(ConsultationRecording(finalWords)); // Will trigger UI to show Process button
      }
    }
  }

  Future<void> _onProcessConsultation(
    ProcessConsultationRequested event,
    Emitter<ConsultationState> emit,
  ) async {
    final transcript = event.finalTranscript;
    if (transcript.isEmpty) {
      emit(const ConsultationError('Transcript is empty.'));
      return;
    }

    emit(ConsultationProcessingAI(transcript));
    try {
      final extractedData = await _repository.extractInstructions(transcript);
      emit(ConsultationSuccess(extractedData));
    } catch (e) {
      emit(ConsultationError(e.toString()));
    }
  }
}
