import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/diagnosis_model.dart';

class DiagnosisFirestoreService {
  DiagnosisFirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('diagnoses');
  }

  CollectionReference<Map<String, dynamic>> get _requireCol {
    final col = _col;
    if (col == null) throw StateError('User belum login.');
    return col;
  }

  /// Simpan diagnosis baru. Mengembalikan model yang sudah punya id dari Firestore.
  Future<DiagnosisModel> addDiagnosis(DiagnosisModel diagnosis) async {
    final col = _requireCol;
    final doc = col.doc();
    final data = diagnosis.toMap()
      ..['diagnosedAt'] = DateTime.now().toIso8601String();
    await doc.set(data);
    return DiagnosisModel.fromMap(data, doc.id);
  }

  /// Stream riwayat diagnosis untuk satu tanaman tertentu.
  Stream<List<DiagnosisModel>> watchDiagnosesByPlant(String plantId) {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .where('plantId', isEqualTo: plantId)
        .orderBy('diagnosedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DiagnosisModel.fromMap(d.data(), d.id)).toList());
  }

  /// Update status perkembangan penyakit.
  Future<void> updateStatus(String id, DiagnosisStatus status) async {
    await _requireCol.doc(id).update({
      'diagnosisStatus': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Hapus satu riwayat diagnosis.
  Future<void> deleteDiagnosis(String id) async {
    await _requireCol.doc(id).delete();
  }
}