import 'package:equatable/equatable.dart';
import '../../../../data/models/saved_recording_model.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object> get props => [];
}

class LoadRecordings extends RecordingEvent {
  final String userId;
  const LoadRecordings(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddRecording extends RecordingEvent {
  final SavedRecordingModel recording;
  const AddRecording(this.recording);

  @override
  List<Object> get props => [recording];
}

class DeleteRecording extends RecordingEvent {
  final String id;
  final String userId;
  const DeleteRecording(this.id, this.userId);

  @override
  List<Object> get props => [id, userId];
}

// STATES

abstract class RecordingState extends Equatable {
  const RecordingState();

  @override
  List<Object> get props => [];
}

class RecordingInitial extends RecordingState {}

class RecordingLoading extends RecordingState {}

class RecordingLoaded extends RecordingState {
  final List<SavedRecordingModel> recordings;
  const RecordingLoaded(this.recordings);

  @override
  List<Object> get props => [recordings];
}

class RecordingError extends RecordingState {
  final String message;
  const RecordingError(this.message);

  @override
  List<Object> get props => [message];
}
