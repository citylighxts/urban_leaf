import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urban_leaf/services/diagnosis_firestore_service.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/plant_model.dart';
// import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
// import '../../ai_scanner/manual_diagnosis_page.dart';
import 'diagnosis_card.dart';
// import 'dart:io'; 

class DiagnosisStreamTab extends StatelessWidget {
  final List<DiagnosisModel> diagnoses;
  final DiagnosisFirestoreService diagnosisService;
  final PlantModel plant;

  const DiagnosisStreamTab({
    super.key,
    required this.diagnoses,
    required this.diagnosisService,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) {
      return const Center(child: Text("Belum ada riwayat penyakit"));
    }

    return ListView.builder(
      itemCount: diagnoses.length,
      itemBuilder: (context, index) {
        final diagnosis = diagnoses[index];
        return DiagnosisCard(diagnosis: diagnosis, diagnosisService: diagnosisService,); 
      },
    );
  }
}

class DiagnosisTab extends StatelessWidget {
  final List<DiagnosisModel> diagnoses;
  final PlantModel plant;
  final DiagnosisFirestoreService diagnosisService;

  const DiagnosisTab({
    required this.diagnoses,
    required this.plant,
    required this.diagnosisService,
  });

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Tidak ada riwayat penyakit',
              style: AppTextStyles.headingSmall,
            ),
            SizedBox(height: 4),
            Text('Tanaman kamu sehat!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: diagnoses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => DiagnosisCard(
        diagnosis: diagnoses[index],
        diagnosisService: diagnosisService,
      ),
    );
  }
}

extension DiagnosisFirestoreServiceDeletion on DiagnosisFirestoreService {
  Future<void> deleteDiagnosis(String diagnosisId, String plantId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('User belum login.');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('plants')
        .doc(plantId)
        .collection('diagnoses')
        .doc(diagnosisId)
        .delete();
  }
}
