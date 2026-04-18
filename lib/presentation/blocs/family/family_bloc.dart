import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/family_repository.dart';
import 'family_event_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _repository;

  FamilyBloc(this._repository) : super(FamilyInitial()) {
    on<LoadFamilyMembers>(_onLoadFamilyMembers);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<DeleteFamilyMember>(_onDeleteFamilyMember);
  }

  Future<void> _onLoadFamilyMembers(LoadFamilyMembers event, Emitter<FamilyState> emit) async {
    try {
      emit(FamilyLoading());
      final members = await _repository.getFamilyMembers(event.parentUserId);
      emit(FamilyLoaded(members));
    } catch (e) {
      emit(FamilyError('Failed to load family members: $e'));
    }
  }

  Future<void> _onAddFamilyMember(AddFamilyMember event, Emitter<FamilyState> emit) async {
    try {
      await _repository.addFamilyMember(event.member);
      // Reload logic
      final members = await _repository.getFamilyMembers(event.member.parentUserId);
      emit(FamilyLoaded(members));
    } catch (e) {
      emit(FamilyError('Failed to add family member: $e'));
    }
  }

  Future<void> _onDeleteFamilyMember(DeleteFamilyMember event, Emitter<FamilyState> emit) async {
    try {
      await _repository.deleteFamilyMember(event.id);
      final members = await _repository.getFamilyMembers(event.parentUserId);
      emit(FamilyLoaded(members));
    } catch (e) {
      emit(FamilyError('Failed to delete family member: $e'));
    }
  }
}
