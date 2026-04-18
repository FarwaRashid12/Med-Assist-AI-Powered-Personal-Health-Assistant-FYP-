import 'package:equatable/equatable.dart';
import '../../../data/models/health_vitals_model.dart';

abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthVitals extends HealthEvent {
  final String userId;

  const LoadHealthVitals(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddHealthVitals extends HealthEvent {
  final HealthVitalsModel vitals;

  const AddHealthVitals(this.vitals);

  @override
  List<Object?> get props => [vitals];
}

class DeleteHealthVitals extends HealthEvent {
  final String vitalsId;
  final String userId;

  const DeleteHealthVitals({required this.vitalsId, required this.userId});

  @override
  List<Object?> get props => [vitalsId, userId];
}

abstract class HealthState extends Equatable {
  const HealthState();

  @override
  List<Object?> get props => [];
}

class HealthInitial extends HealthState {
  const HealthInitial();
}

class HealthLoading extends HealthState {
  const HealthLoading();
}

class HealthLoaded extends HealthState {
  final List<HealthVitalsModel> vitals;

  const HealthLoaded(this.vitals);

  @override
  List<Object?> get props => [vitals];
}

class HealthError extends HealthState {
  final String message;

  const HealthError(this.message);

  @override
  List<Object?> get props => [message];
}
