import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_type_model.dart';

class PlantTypeService {
  static const _collection = 'plant_types';
  final _db = FirebaseFirestore.instance;

  // Scientifically-backed tolerance data.
  // Sources: FAO Crop Production Guidelines, USDA Plant Hardiness,
  // Hochmuth et al. (UF/IFAS), and standard horticultural references.
  static const List<PlantTypeModel> _seedData = [
    PlantTypeModel(
      id: 'selada',
      name: 'Selada',
      emoji: '🥬',
      minTemp: 7,
      maxTemp: 24,
      minHumidity: 60,
      maxHumidity: 70,
    ),
    PlantTypeModel(
      id: 'tomat',
      name: 'Tomat',
      emoji: '🍅',
      minTemp: 15,
      maxTemp: 32,
      minHumidity: 65,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'cabai',
      name: 'Cabai',
      emoji: '🌶️',
      minTemp: 20,
      maxTemp: 30,
      minHumidity: 65,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'paprika',
      name: 'Paprika',
      emoji: '🫑',
      minTemp: 18,
      maxTemp: 28,
      minHumidity: 65,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'timun',
      name: 'Timun',
      emoji: '🥒',
      minTemp: 21,
      maxTemp: 29,
      minHumidity: 70,
      maxHumidity: 90,
    ),
    PlantTypeModel(
      id: 'pakcoy',
      name: 'Pakcoy',
      emoji: '🥦',
      minTemp: 15,
      maxTemp: 25,
      minHumidity: 65,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'bayam',
      name: 'Bayam',
      emoji: '🌿',
      minTemp: 10,
      maxTemp: 22,
      minHumidity: 60,
      maxHumidity: 70,
    ),
    PlantTypeModel(
      id: 'kangkung',
      name: 'Kangkung',
      emoji: '🌱',
      minTemp: 25,
      maxTemp: 35,
      minHumidity: 70,
      maxHumidity: 90,
    ),
    PlantTypeModel(
      id: 'sawi',
      name: 'Sawi',
      emoji: '🥬',
      minTemp: 15,
      maxTemp: 25,
      minHumidity: 60,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'terong',
      name: 'Terong',
      emoji: '🍆',
      minTemp: 22,
      maxTemp: 30,
      minHumidity: 60,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'stroberi',
      name: 'Stroberi',
      emoji: '🍓',
      minTemp: 15,
      maxTemp: 26,
      minHumidity: 65,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'jagung',
      name: 'Jagung',
      emoji: '🌽',
      minTemp: 18,
      maxTemp: 32,
      minHumidity: 50,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'kentang',
      name: 'Kentang',
      emoji: '🥔',
      minTemp: 10,
      maxTemp: 25,
      minHumidity: 60,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'kedelai',
      name: 'Kedelai',
      emoji: '🫘',
      minTemp: 20,
      maxTemp: 32,
      minHumidity: 55,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'labu',
      name: 'Labu',
      emoji: '🎃',
      minTemp: 18,
      maxTemp: 30,
      minHumidity: 55,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'apel',
      name: 'Apel',
      emoji: '🍎',
      minTemp: 7,
      maxTemp: 24,
      minHumidity: 60,
      maxHumidity: 70,
    ),
    PlantTypeModel(
      id: 'anggur',
      name: 'Anggur',
      emoji: '🍇',
      minTemp: 15,
      maxTemp: 30,
      minHumidity: 50,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'jeruk',
      name: 'Jeruk',
      emoji: '🍊',
      minTemp: 13,
      maxTemp: 28,
      minHumidity: 60,
      maxHumidity: 80,
    ),
    PlantTypeModel(
      id: 'blueberry',
      name: 'Blueberry',
      emoji: '🫐',
      minTemp: 13,
      maxTemp: 24,
      minHumidity: 55,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'raspberry',
      name: 'Raspberry',
      emoji: '🍒',
      minTemp: 13,
      maxTemp: 24,
      minHumidity: 60,
      maxHumidity: 70,
    ),
    PlantTypeModel(
      id: 'persik',
      name: 'Persik',
      emoji: '🍑',
      minTemp: 15,
      maxTemp: 25,
      minHumidity: 55,
      maxHumidity: 75,
    ),
    PlantTypeModel(
      id: 'lainnya',
      name: 'Lainnya',
      emoji: '🌸',
      minTemp: 15,
      maxTemp: 30,
      minHumidity: 50,
      maxHumidity: 80,
    ),
  ];

  Future<List<PlantTypeModel>> fetchAll() async {
    final snap = await _db
        .collection(_collection)
        .orderBy('name')
        .get();
    return snap.docs
        .map((d) => PlantTypeModel.fromMap(d.data()))
        .toList();
  }

  /// Seeds the collection only if it is empty.
  Future<void> seedIfEmpty() async {
    final snap = await _db
        .collection(_collection)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final type in _seedData) {
      final ref = _db.collection(_collection).doc(type.id);
      batch.set(ref, type.toMap());
    }
    await batch.commit();
  }
}
