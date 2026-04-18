import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Register a new user with Email/Password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Create user profile in Firestore
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': fullName.trim(),
        'email': email.toLowerCase().trim(),
        'phone': phone?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  /// Login with Email/Password
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete profile from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      // Delete auth account
      await user.delete();
    }
  }

  /// Get user profile from Firestore
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      // Re-throw with a descriptive message or return a state indicating error
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    Map<String, dynamic>? data,
  }) async {
    if (data != null && data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(data);
    }
  }
}
