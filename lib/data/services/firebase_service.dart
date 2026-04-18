import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_prescription_model.dart';

/// One-stop service for all Firebase operations (Auth + Firestore)
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Authentication ---

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

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

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  // --- Users ---

  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // --- Prescriptions (Reports) ---

  Future<void> savePrescription(SavedPrescriptionModel prescription) {
    return _firestore
        .collection('prescriptions')
        .doc(prescription.id)
        .set(prescription.toFirestore());
  }

  Future<List<SavedPrescriptionModel>> getPrescriptionsForUser(String userId) async {
    final snapshot = await _firestore
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => SavedPrescriptionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> deletePrescription(String id) {
    return _firestore.collection('prescriptions').doc(id).delete();
  }
}
