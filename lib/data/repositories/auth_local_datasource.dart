import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_model.dart';

class AuthLocalDataSource {
  static const String _usersBoxName = 'users';
  static const String _sessionBoxName = 'session';
  static const String _currentUserKey = 'current_user_id';

  Future<Box<UserModel>> get _usersBox async =>
      Hive.openBox<UserModel>(_usersBoxName);

  Future<Box<dynamic>> get _sessionBox async =>
      Hive.openBox(_sessionBoxName);

  Future<void> registerUser(UserModel user) async {
    final box = await _usersBox;
    await box.put(user.email, user);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final box = await _usersBox;
    return box.get(email);
  }

  Future<bool> emailExists(String email) async {
    final box = await _usersBox;
    return box.containsKey(email);
  }

  Future<void> updateUser(UserModel user) async {
    final box = await _usersBox;
    await box.put(user.email, user);
  }

  Future<void> deleteUser(String email) async {
    final box = await _usersBox;
    await box.delete(email);
  }

  Future<void> saveSession(String userId) async {
    final box = await _sessionBox;
    await box.put(_currentUserKey, userId);
  }

  Future<String?> getSessionUserId() async {
    final box = await _sessionBox;
    return box.get(_currentUserKey) as String?;
  }

  Future<void> clearSession() async {
    final box = await _sessionBox;
    await box.delete(_currentUserKey);
  }

  Future<UserModel?> getLoggedInUser() async {
    final userId = await getSessionUserId();
    if (userId == null) return null;
    final box = await _usersBox;
    return box.get(userId);
  }
}
