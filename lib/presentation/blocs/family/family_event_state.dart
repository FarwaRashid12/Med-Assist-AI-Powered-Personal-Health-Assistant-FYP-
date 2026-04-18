import 'package:equatable/equatable.dart';
import '../../../../data/models/family_profile_model.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object> get props => [];
}

class LoadFamilyMembers extends FamilyEvent {
  final String parentUserId;

  const LoadFamilyMembers(this.parentUserId);

  @override
  List<Object> get props => [parentUserId];
}

class AddFamilyMember extends FamilyEvent {
  final FamilyProfileModel member;

  const AddFamilyMember(this.member);

  @override
  List<Object> get props => [member];
}

class DeleteFamilyMember extends FamilyEvent {
  final String id;
  final String parentUserId;

  const DeleteFamilyMember(this.id, this.parentUserId);

  @override
  List<Object> get props => [id, parentUserId];
}


// States

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object> get props => [];
}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyProfileModel> members;

  const FamilyLoaded(this.members);

  @override
  List<Object> get props => [members];
}

class FamilyError extends FamilyState {
  final String message;

  const FamilyError(this.message);

  @override
  List<Object> get props => [message];
}
