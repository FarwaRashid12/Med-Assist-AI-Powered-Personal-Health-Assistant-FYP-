import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/health_repository.dart';
import 'health_event_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final HealthRepository _repository;

  HealthBloc(this._repository) : super(const HealthInitial()) {
    on<LoadHealthVitals>(_onLoadHealthVitals);
    on<AddHealthVitals>(_onAddHealthVitals);
    on<DeleteHealthVitals>(_onDeleteHealthVitals);
  }

  Future<void> _onLoadHealthVitals(
    LoadHealthVitals event,
    Emitter<HealthState> emit,
  ) async {
    emit(const HealthLoading());
    try {
      final vitals = await _repository.getVitalsHistory(event.userId);
      emit(HealthLoaded(vitals));
    } catch (e) {
      emit(HealthError('Failed to load health history: $e'));
    }
  }

  Future<void> _onAddHealthVitals(
    AddHealthVitals event,
    Emitter<HealthState> emit,
  ) async {
    try {
      await _repository.addVitals(event.vitals);
      
      // Small delay to ensure Hive has committed the write to disk on slower file systems
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Force a reload to ensure the UI is synchronized with the fresh database entry
      final vitals = await _repository.getVitalsHistory(event.vitals.userId);
      emit(HealthLoaded(vitals));
    } catch (e) {
      emit(HealthError('Failed to add vitals: $e'));
    }
  }
  Future<void> _onDeleteHealthVitals(
    DeleteHealthVitals event,
    Emitter<HealthState> emit,
  ) async {
    try {
      await _repository.deleteVitals(event.vitalsId);
      final vitals = await _repository.getVitalsHistory(event.userId);
      emit(HealthLoaded(vitals));
    } catch (e) {
      emit(HealthError('Failed to delete vitals entry: $e'));
    }
  }
}
