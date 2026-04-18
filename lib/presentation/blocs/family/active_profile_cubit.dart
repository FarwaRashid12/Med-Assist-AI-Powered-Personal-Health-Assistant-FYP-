import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveProfileCubit extends Cubit<String> {
  // Empty string implies the "Primary User" is selected.
  ActiveProfileCubit() : super('');

  void selectProfile(String name) {
    emit(name);
  }

  void resetToPrimary() {
    emit('');
  }
  String getCompositeUserId(String baseUserId, String primaryUserName) {
    if (state.isEmpty || state == primaryUserName) return baseUserId;
    return '${baseUserId}_$state';
  }
}
