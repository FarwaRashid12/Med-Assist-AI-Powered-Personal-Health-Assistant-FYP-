import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_prescription_model.dart';

class PrescriptionFirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'prescriptions';

  /// Save a new prescription or update an existing one
  Future<void> savePrescription(SavedPrescriptionModel prescription) async {
    await _firestore
        .collection(collectionName)
        .doc(prescription.id)
        .set(prescription.toFirestore());
  }

  /// Get all prescriptions for a specific user
  Future<List<SavedPrescriptionModel>> getPrescriptionsForUser(String userId) async {
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => SavedPrescriptionModel.fromFirestore(
              doc.data(),
              doc.id,
            ))
        .toList();
  }

  /// Delete a prescription
  Future<void> deletePrescription(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  /// Stream prescriptions for a user (useful for real-time updates)
  Stream<List<SavedPrescriptionModel>> watchPrescriptionsForUser(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedPrescriptionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
