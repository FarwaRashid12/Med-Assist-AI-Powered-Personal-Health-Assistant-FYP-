import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/models/saved_prescription_model.dart';

// -- Events -- //

abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzePrescriptionRequested extends PrescriptionEvent {
  final File imageFile;
  final File? audioFile;
  final Map<String, String>? vitals;

  const AnalyzePrescriptionRequested(this.imageFile, {this.audioFile, this.vitals});

  @override
  List<Object?> get props => [imageFile.path, audioFile?.path, vitals];
}

class SavePrescriptionRequested extends PrescriptionEvent {
  final SavedPrescriptionModel prescription;
  const SavePrescriptionRequested(this.prescription);

  @override
  List<Object?> get props => [prescription.id];
}

class LoadSavedPrescriptions extends PrescriptionEvent {
  final String userId;
  const LoadSavedPrescriptions(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ResetPrescription extends PrescriptionEvent {
  const ResetPrescription();
}

class DeleteSavedPrescription extends PrescriptionEvent {
  final String prescriptionId;
  final String userId;
  const DeleteSavedPrescription(this.prescriptionId, this.userId);

  @override
  List<Object?> get props => [prescriptionId, userId];
}

class UpdateSavedPrescription extends PrescriptionEvent {
  final SavedPrescriptionModel prescription;
  final String userId;
  const UpdateSavedPrescription(this.prescription, this.userId);

  @override
  List<Object?> get props => [prescription.id, userId];
}

// -- States -- //

abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

class PrescriptionInitial extends PrescriptionState {
  const PrescriptionInitial();
}

class PrescriptionAnalyzing extends PrescriptionState {
  final File imageFile;
  const PrescriptionAnalyzing(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

class PrescriptionSuccess extends PrescriptionState {
  final PrescriptionModel prescription;
  final File imageFile;
  final File? audioFile;
  final Map<String, String>? vitals;
  const PrescriptionSuccess(this.prescription, this.imageFile, {this.audioFile, this.vitals});

  @override
  List<Object?> get props => [prescription, imageFile.path, audioFile?.path, vitals];
}

class PrescriptionSaved extends PrescriptionState {
  const PrescriptionSaved();
}

class SavedPrescriptionsLoaded extends PrescriptionState {
  final List<SavedPrescriptionModel> prescriptions;
  const SavedPrescriptionsLoaded(this.prescriptions);

  @override
  List<Object?> get props => [prescriptions];
}

class PrescriptionError extends PrescriptionState {
  final String message;
  const PrescriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
