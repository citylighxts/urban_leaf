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

  CollectionReference<Map<String, dynamic>>? get _plantsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('plants');
  }

  Stream<List<PlantModel>> watchPlants() {
    final collection = _plantsCollection;
    if (collection == null) {
      return Stream<List<PlantModel>>.value(const []);
    }

    return collection.orderBy('updatedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      final plants = snapshot.docs
          .map((doc) => PlantModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      for (final doc in snapshot.docs) {
        final plant = PlantModel.fromMap({...doc.data(), 'id': doc.id});
        _syncWateringStatus(doc.reference, plant);
      }

      return plants;
    });
  }

  void _syncWateringStatus(
    DocumentReference<Map<String, dynamic>> reference,
    PlantModel plant,
  ) {
    if (plant.status == PlantStatus.quarantine ||
        plant.status == PlantStatus.needsAttention) {
      return;
    }

    final now = DateTime.now();
    final shouldNeedAttention = plant.lastWateredAt != null
        ? now.difference(plant.lastWateredAt!) >= const Duration(hours: 24)
        : plant.nextWatering.isBefore(now);

    if (!shouldNeedAttention) return;

    unawaited(
      reference.update({
        'status': PlantStatus.needsAttention.name,
        'updatedAt': now,
      }),
    );
  }

  Future<PlantModel> addPlant(PlantModel plant) async {
    final collection = _requireCollection();
    final doc = collection.doc();
    final now = DateTime.now();

    final data = plant.toMap()
      ..remove('id')
      ..addAll({'createdAt': now, 'updatedAt': now});

    await doc.set(data);

    return PlantModel.fromMap({...data, 'id': doc.id});
  }

  Future<PlantModel> updatePlant(PlantModel plant) async {
    final collection = _requireCollection();
    final now = DateTime.now();

    final data = plant.toMap()
      ..remove('id')
      ..addAll({'updatedAt': now});

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
}
