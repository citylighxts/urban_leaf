import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/alert_model.dart';

class AlertFirestoreService {
  AlertFirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('alerts');
  }

  CollectionReference<Map<String, dynamic>> get _requireCol {
    final col = _col;
    if (col == null) throw StateError('User belum login.');
    return col;
  }

  /// Hapus semua auto-generated alerts lama lalu simpan yang baru.
  Future<void> saveAlerts(List<AlertModel> alerts) async {
    final col = _requireCol;
    final existing = await col.get();
    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      if (doc.id.startsWith('auto_') || doc.id.startsWith('tolerance_')) {
        batch.delete(doc.reference);
      }
    }
    for (final alert in alerts) {
      batch.set(col.doc(alert.id), alert.toMap());
    }
    await batch.commit();
  }

  /// Stream semua alert milik user, diurutkan dari terbaru.
  Stream<List<AlertModel>> watchAlerts() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => AlertModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Update status sebuah alert (ditangani / diabaikan).
  Future<void> updateStatus(String id, AlertStatus status) async {
    await _requireCol.doc(id).update({'status': status.name});
  }

  /// Hapus satu alert.
  Future<void> deleteAlert(String id) async {
    await _requireCol.doc(id).delete();
  }

  /// Hapus semua alert yang sudah ditangani/diabaikan.
  Future<void> deleteOldAlerts() async {
    final col = _requireCol;
    final snap = await col
        .where('status', whereIn: [
          AlertStatus.handled.name,
          AlertStatus.dismissed.name,
        ])
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
