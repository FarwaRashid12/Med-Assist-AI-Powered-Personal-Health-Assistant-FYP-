import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final user = await _authRepository.getLoggedInUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final response = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    switch (response.result) {
      case AuthResult.success:
        emit(AuthAuthenticated(response.user!));
        break;
      case AuthResult.invalidCredentials:
        emit(const AuthError('Invalid email or password. Please try again.'));
        break;
      case AuthResult.error:
        emit(AuthError(response.error ?? 'Something went wrong.'));
        break;
      default:
        emit(const AuthError('Something went wrong.'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final response = await _authRepository.register(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      phone: event.phone,
    );

    switch (response.result) {
      case AuthResult.success:
        emit(AuthRegisterSuccess(response.user!));
        break;
      case AuthResult.emailAlreadyExists:
        emit(const AuthError('An account with this email already exists.'));
        break;
      case AuthResult.error:
        emit(AuthError(response.error ?? 'Something went wrong.'));
        break;
      default:
        emit(const AuthError('Something went wrong.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = await _authRepository.getLoggedInUser();
    if (currentUser == null) return;

    emit(const AuthLoading());
    final response = await _authRepository.changePassword(
      oldPassword: event.oldPassword,
      newPassword: event.newPassword,
    );

    if (response.result == AuthResult.success) {
      emit(const AuthMessage('Password changed successfully.'));
      // re-emit authenticated state to keep the user signed in on UI
      emit(AuthAuthenticated(currentUser));
    } else {
      emit(AuthError(response.error ?? 'Failed to change password.'));
      // Keep user in authenticated state despite error
      emit(AuthAuthenticated(currentUser));
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final response = await _authRepository.deleteAccount();

    if (response.result == AuthResult.success) {
      emit(const AuthMessage('Account deleted successfully.'));
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthError(response.error ?? 'Failed to delete account.'));
      final currentUser = await _authRepository.getLoggedInUser();
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(const AuthUnauthenticated());
      }
    }
  }
}
