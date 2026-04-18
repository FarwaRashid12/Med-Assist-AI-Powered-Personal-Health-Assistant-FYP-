import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../data/models/user_model.dart';
import '../../data/services/firebase_service.dart';

enum AuthResult { success, emailAlreadyExists, invalidCredentials, weakPassword, error }

class AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepository(this._firebaseService);

  Future<({AuthResult result, UserModel? user, String? error})> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final credential = await _firebaseService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          fullName: fullName.trim(),
          email: email.toLowerCase().trim(),
          passwordHash: '', 
          phone: phone?.trim(),
          createdAt: DateTime.now(),
        );
        return (result: AuthResult.success, user: user, error: null);
      }
      return (result: AuthResult.error, user: null, error: 'Registration failed');
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return (result: AuthResult.emailAlreadyExists, user: null, error: null);
      } else if (e.code == 'weak-password') {
        return (result: AuthResult.weakPassword, user: null, error: null);
      }
      return (result: AuthResult.error, user: null, error: e.message);
    } catch (e) {
      return (result: AuthResult.error, user: null, error: e.toString());
    }
  }

  Future<({AuthResult result, UserModel? user, String? error})> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseService.login(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final profileDoc = await _firebaseService.getUserProfile(credential.user!.uid);
        final user = UserModel.fromMap(
          profileDoc.data() as Map<String, dynamic>,
          credential.user!.uid,
        );
        return (result: AuthResult.success, user: user, error: null);
      }
      return (result: AuthResult.error, user: null, error: 'Login failed');
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return (result: AuthResult.invalidCredentials, user: null, error: null);
      }
      return (result: AuthResult.error, user: null, error: e.message);
    } catch (e) {
      return (result: AuthResult.error, user: null, error: e.toString());
    }
  }

  Future<({AuthResult result, String? error})> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user = firebase.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return (result: AuthResult.error, error: 'User not logged in');
      }

      // Re-authenticate user before changing password
      final cred = firebase.EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      
      return (result: AuthResult.success, error: null);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return (result: AuthResult.invalidCredentials, error: 'Incorrect old password');
      }
      return (result: AuthResult.error, error: e.message);
    } catch (e) {
      return (result: AuthResult.error, error: e.toString());
    }
  }

  Future<({AuthResult result, String? error})> deleteAccount() async {
    try {
      await _firebaseService.deleteAccount();
      return (result: AuthResult.success, error: null);
    } on firebase.FirebaseAuthException catch (e) {
      return (result: AuthResult.error, error: e.message);
    } catch (e) {
      return (result: AuthResult.error, error: e.toString());
    }
  }

  Future<UserModel?> getLoggedInUser() async {
    final firebaseUser = _firebaseService.currentUser;
    if (firebaseUser != null) {
      final profileDoc = await _firebaseService.getUserProfile(firebaseUser.uid);
      if (profileDoc.exists) {
        return UserModel.fromMap(
          profileDoc.data() as Map<String, dynamic>,
          firebaseUser.uid,
        );
      }
    }
    return null;
  }

  Future<void> logout() => _firebaseService.logout();
}
