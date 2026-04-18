import 'package:equatable/equatable.dart';
import 'package:medassist/data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  const RegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [fullName, email, password, phone];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class DeleteAccountRequested extends AuthEvent {
  const DeleteAccountRequested();
}


// ─── States ────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegisterSuccess extends AuthState {
  final UserModel user;
  const AuthRegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthMessage extends AuthState {
  final String message;
  const AuthMessage(this.message);

  @override
  List<Object?> get props => [message];
}
