import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/recording_repository.dart';
import 'recording_event_state.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final RecordingRepository _repository;

  RecordingBloc(this._repository) : super(RecordingInitial()) {
    on<LoadRecordings>(_onLoadRecordings);
    on<AddRecording>(_onAddRecording);
    on<DeleteRecording>(_onDeleteRecording);
  }

  Future<void> _onLoadRecordings(LoadRecordings event, Emitter<RecordingState> emit) async {
    try {
      emit(RecordingLoading());
      final recordings = await _repository.getRecordings(event.userId);
      emit(RecordingLoaded(recordings));
    } catch (e) {
      emit(RecordingError('Failed to load recordings: $e'));
    }
  }

  Future<void> _onAddRecording(AddRecording event, Emitter<RecordingState> emit) async {
    try {
      await _repository.saveRecording(event.recording);
      final recordings = await _repository.getRecordings(event.recording.userId);
      emit(RecordingLoaded(recordings));
    } catch (e) {
      emit(RecordingError('Failed to save recording: $e'));
    }
  }

  Future<void> _onDeleteRecording(DeleteRecording event, Emitter<RecordingState> emit) async {
    try {
      await _repository.deleteRecording(event.id);
      final recordings = await _repository.getRecordings(event.userId);
      emit(RecordingLoaded(recordings));
    } catch (e) {
      emit(RecordingError('Failed to delete recording: $e'));
    }
  }
}
