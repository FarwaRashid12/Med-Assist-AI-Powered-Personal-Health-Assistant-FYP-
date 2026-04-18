import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/prescription_repository.dart';
import '../../../data/services/firebase_service.dart';
import 'prescription_event_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final PrescriptionRepository _repository;
  final FirebaseService _firebaseService;

  PrescriptionBloc(this._repository, this._firebaseService) : super(const PrescriptionInitial()) {
    on<AnalyzePrescriptionRequested>(_onAnalyze);
    on<SavePrescriptionRequested>(_onSave);
    on<LoadSavedPrescriptions>(_onLoad);
    on<ResetPrescription>(_onReset);
    on<DeleteSavedPrescription>(_onDelete);
    on<UpdateSavedPrescription>(_onUpdate);
  }

  Future<void> _onAnalyze(
    AnalyzePrescriptionRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(PrescriptionAnalyzing(event.imageFile));
    try {
      final result = await _repository.analyzePrescription(
        event.imageFile,
        audioFile: event.audioFile,
      );

      final mergedVitals = <String, String>{};
      
      // Auto-extract from AI first map
      if (result.extractedVitals != null) {
        mergedVitals.addAll(result.extractedVitals!);
      }
      
      // Override or append Manual inputs from Scanner
      if (event.vitals != null) {
        mergedVitals.addAll(event.vitals!);
      }

      emit(PrescriptionSuccess(result, event.imageFile, audioFile: event.audioFile, vitals: mergedVitals.isNotEmpty ? mergedVitals : null));
    } catch (e) {
      emit(PrescriptionError(e.toString()));
    }
  }

  Future<void> _onSave(
    SavePrescriptionRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      await _firebaseService.savePrescription(event.prescription);
      emit(const PrescriptionSaved());
    } catch (e) {
      emit(PrescriptionError('Failed to save: $e'));
    }
  }

  Future<void> _onLoad(
    LoadSavedPrescriptions event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      final prescriptions = await _firebaseService.getPrescriptionsForUser(event.userId);
      emit(SavedPrescriptionsLoaded(prescriptions));
    } catch (e) {
      emit(PrescriptionError('Failed to load prescriptions: $e'));
    }
  }

  void _onReset(
    ResetPrescription event,
    Emitter<PrescriptionState> emit,
  ) {
    emit(const PrescriptionInitial());
  }

  Future<void> _onDelete(
    DeleteSavedPrescription event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      await _firebaseService.deletePrescription(event.prescriptionId);
      // Reload after delete
      final prescriptions = await _firebaseService.getPrescriptionsForUser(event.userId);
      emit(SavedPrescriptionsLoaded(prescriptions));
    } catch (e) {
      emit(PrescriptionError('Failed to delete prescription: $e'));
    }
  }

  Future<void> _onUpdate(
    UpdateSavedPrescription event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      await _firebaseService.savePrescription(event.prescription);
      final prescriptions = await _firebaseService.getPrescriptionsForUser(event.userId);
      emit(SavedPrescriptionsLoaded(prescriptions));
    } catch (e) {
      emit(PrescriptionError('Failed to update prescription: $e'));
    }
  }
}
