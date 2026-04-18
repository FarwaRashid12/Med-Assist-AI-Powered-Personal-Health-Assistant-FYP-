import 'package:equatable/equatable.dart';
import '../../../data/models/consultation_model.dart';

abstract class ConsultationEvent extends Equatable {
  const ConsultationEvent();

  @override
  List<Object?> get props => [];
}

class StartRecordingRequested extends ConsultationEvent {
  const StartRecordingRequested();
}

class UpdateTranscriptEvent extends ConsultationEvent {
  final String partialTranscript;
  final bool isFinal;

  const UpdateTranscriptEvent(this.partialTranscript, {this.isFinal = false});

  @override
  List<Object?> get props => [partialTranscript, isFinal];
}

class StopRecordingRequested extends ConsultationEvent {
  const StopRecordingRequested();
}

class ProcessConsultationRequested extends ConsultationEvent {
  final String finalTranscript;

  const ProcessConsultationRequested(this.finalTranscript);

  @override
  List<Object?> get props => [finalTranscript];
}

// -- States -- //

abstract class ConsultationState extends Equatable {
  const ConsultationState();

  @override
  List<Object?> get props => [];
}

class ConsultationInitial extends ConsultationState {
  const ConsultationInitial();
}

class ConsultationRecording extends ConsultationState {
  final String transcript;
  const ConsultationRecording(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

class ConsultationProcessingAI extends ConsultationState {
  final String transcript;
  const ConsultationProcessingAI(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

class ConsultationSuccess extends ConsultationState {
  final ConsultationModel model;
  const ConsultationSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

class ConsultationError extends ConsultationState {
  final String error;
  const ConsultationError(this.error);

  @override
  List<Object?> get props => [error];
}
