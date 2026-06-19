import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';

class PlantFirestoreService {
  PlantFirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  // final CollectionReference _col = FirebaseFirestore.instance.collection('plants');

  CollectionReference<Map<String, dynamic>>? get _plantsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('plants');
  }

  Stream<List<PlantModel>> watchPlants() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(<PlantModel>[]);
      }

      final collection = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('plants');

      return collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return PlantModel.fromMap({...data, 'id': doc.id});
            }).toList();
          });
    });
  }

  // Di PlantFirestoreService.dart
  Future<PlantModel> addPlant(PlantModel plant) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User tidak login");

    final userDocRef = _firestore.collection('users').doc(uid);
    
    // 1. Pastikan dokumen user ada (karena jika tidak, sub-koleksi plants mungkin gagal)
    await userDocRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    // 2. Sekarang baru tambah tanaman
    final doc = userDocRef.collection('plants').doc();
    final serverNow = FieldValue.serverTimestamp();
    final data = plant.toMap()
      ..remove('id')
      ..addAll({
        'createdAt': serverNow,
        'updatedAt': serverNow,
      });

    await doc.set(data);
    return plant.copyWith(id: doc.id);
  }

  Future<PlantModel> updatePlant(PlantModel plant) async {
    final collection = _requireCollection();

    final data = plant.toMap()
      ..remove('id')
      ..addAll({'updatedAt': FieldValue.serverTimestamp()});

    await collection.doc(plant.id).set(data, SetOptions(merge: true));

    return plant;
  }

  Future<void> deletePlant(String id) async {
    final collection = _requireCollection();
    await collection.doc(id).delete();
  }

  CollectionReference<Map<String, dynamic>> _requireCollection() {
    final collection = _plantsCollection;
    if (collection == null) {
      throw StateError('User belum login.');
    }
    return collection;
  }

  Future<void> updatePlantStatus(String plantId, PlantStatus newStatus) async {
    final collection = _requireCollection();

    await collection.doc(plantId).update({
      'status': newStatus.name, // Firestore akan mengupdate status di koleksi 'plants'
      'updatedAt': DateTime.now(),
    });
  }
}
