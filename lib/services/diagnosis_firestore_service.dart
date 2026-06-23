import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urban_leaf/models/plant_model.dart';
import 'package:urban_leaf/services/plant_firestore_service.dart';
import '../models/diagnosis_model.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Tambahkan ini
import 'dart:io';

class DiagnosisFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlantFirestoreService _plantService = PlantFirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _getDiagnosesCol(String plantId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User belum login.');
    
    return _firestore.collection('users').doc(uid)
        .collection('plants').doc(plantId)
        .collection('diagnoses');
  }

   Future<String?> _uploadImageToStorage(String plantId, File imageFile) async {
    try {
      // 1. Pastikan file ada
      if (!await imageFile.exists()) {
        print("Error: File lokal tidak ditemukan di path: ${imageFile.path}");
        return null;
      }

      final userId = _auth.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 2. Buat referensi storage
      final ref = _storage.ref().child('users/$userId/plants/$plantId/diagnoses/$fileName');
      
      // 3. Upload file
      // putFile akan otomatis membuat folder jika belum ada di Firebase Storage
      final taskSnapshot = await ref.putFile(imageFile);
      
      // 4. Ambil URL setelah upload selesai
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Gagal upload gambar: $e");
      return null;
    }
  }

  Future<void> addDiagnosis(String plantId, DiagnosisModel diagnosis, File? imageFile) async {
    print("DEBUG: Nilai imageFile saat ini adalah: $imageFile");
    
    String? imageUrl = diagnosis.imagePath;
    // Jika ada file lokal, upload ke Cloud Storage
    if (imageFile != null) {
      imageUrl = await _uploadImageToStorage(plantId, imageFile);
    }

    final userId = _auth.currentUser!.uid;
    final batch = _firestore.batch();
    final diagRef = _getDiagnosesCol(plantId).doc();

    final data = diagnosis.toMap();
    data['id'] = diagRef.id; 
    data['imagePath'] = imageUrl;

    batch.set(diagRef, data);
    // Update status tanaman di koleksi 'plants'
    final plantRef = _firestore.collection('users').doc(userId)
        .collection('plants').doc(plantId);
        
    batch.update(plantRef, {
      'status': diagnosis.diagnosisStatus == DiagnosisStatus.active 
                ? PlantStatus.quarantine.name 
                : PlantStatus.needsAttention.name,
      'lastDiagnosis': diagnosis.diseaseName,
      'diseaseHistory': FieldValue.arrayUnion([diagnosis.diseaseName]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<DiagnosisModel>> watchDiagnosesByPlant(String plantId) {
    return _getDiagnosesCol(plantId)
        .snapshots()
        .map((snap) {
          final diagnoses = snap.docs
              .map((d) => DiagnosisModel.fromMap(d.data(), d.id))
              .toList();

          diagnoses.sort((a, b) => b.diagnosedAt.compareTo(a.diagnosedAt));
          return diagnoses;
        });
  }

  Future<void> updateStatus(String diagnosisId, DiagnosisStatus status, String plantId) async {
    // Update di koleksi diagnoses (lokal tanaman)
    await _getDiagnosesCol(plantId).doc(diagnosisId).update({'diagnosisStatus': status.name});
    
    // Update status utama tanaman
    final newPlantStatus = switch (status) {
      DiagnosisStatus.active => PlantStatus.quarantine,
      DiagnosisStatus.recovering => PlantStatus.needsAttention,
      DiagnosisStatus.resolved => PlantStatus.healthy,
    };
    await _plantService.updatePlantStatus(plantId, newPlantStatus);
  }

  Future<void> deleteDiagnosis(String diagnosisId, String plantId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User belum login.');

    final diagnosisRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .collection('diagnoses')
        .doc(diagnosisId);
    final plantRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId);

    final batch = _firestore.batch();
    batch.delete(diagnosisRef);

    batch.update(plantRef, {
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final remainingDocs = await _getDiagnosesCol(plantId).get();
    if (remainingDocs.docs.isEmpty) {
      await plantRef.update({
        'status': PlantStatus.healthy.name,
        'lastDiagnosis': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateDiagnosis(String plantId, DiagnosisModel diagnosis) async {
    if (diagnosis.id.isEmpty) {
      throw StateError('ID diagnosis tidak boleh kosong saat update.');
    }

    final diagnosisRef = _getDiagnosesCol(plantId).doc(diagnosis.id);
    final plantRef = _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('plants')
        .doc(plantId);

    final diagnosisDoc = await diagnosisRef.get();
    if (!diagnosisDoc.exists) {
      throw StateError(
        'Dokumen diagnosis tidak ditemukan di path: ${diagnosisRef.path}',
      );
    }

    await diagnosisRef.update({
      'id': diagnosis.id,
      'plantId': diagnosis.plantId,
      'plantName': diagnosis.plantName,
      'plantEmoji': diagnosis.plantEmoji,
      'diseaseName': diagnosis.diseaseName,
      'diseaseNameEn': diagnosis.diseaseNameEn,
      'diagnosisStatus': diagnosis.diagnosisStatus.name,
      'confidence': diagnosis.confidence,
      'description': diagnosis.description,
      'solutions': diagnosis.solutions,
      'preventionTips': diagnosis.preventionTips,
      'diagnosedAt': Timestamp.fromDate(diagnosis.diagnosedAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'imagePath': diagnosis.imagePath,
      'isManual': diagnosis.isManual,
    });

    await plantRef.update({
      'lastDiagnosis': diagnosis.diseaseName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

}