import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/diagnosis_model.dart';
import '../../services/diagnosis_firestore_service.dart';

class ManualDiagnosisPage extends StatefulWidget {
  final File imageFile;
  const ManualDiagnosisPage({super.key, required this.imageFile});

  @override
  State<ManualDiagnosisPage> createState() => _ManualDiagnosisPageState();
}

class _ManualDiagnosisPageState extends State<ManualDiagnosisPage> {
  final _gejalaController = TextEditingController();
  final _solusiController = TextEditingController();
  final _service = DiagnosisFirestoreService();

  void _saveManual() async {
  // Tambahkan parameter yang wajib ada di DiagnosisModel
  final diagnosis = DiagnosisModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    plantId: 'manual', // Beri nilai dummy atau null jika model mengizinkan
    plantName: 'Manual Diagnosis', 
    plantEmoji: '📝',
    diseaseName: _gejalaController.text,
    description: _solusiController.text,
    isManual: true, // Pastikan field ini ada di model
    diagnosedAt: DateTime.now(),
    severity: DiseaseSeverity.mild,
    diagnosisStatus: DiagnosisStatus.active,
    confidence: 1.0,
    solutions: [],
    preventionTips: [], diseaseNameEn: _gejalaController.text,
    imagePath: widget.imageFile.path, // Simpan path lokal file di sini
    
  );
  await _service.addDiagnosis(diagnosis);
  Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diagnosa Manual")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.file(widget.imageFile, height: 200),
            TextField(controller: _gejalaController, decoration: const InputDecoration(labelText: "Gejala Penyakit")),
            TextField(controller: _solusiController, decoration: const InputDecoration(labelText: "Rencana Pengobatan (Opsional)")),
            ElevatedButton(onPressed: _saveManual, child: const Text("Simpan")),
          ],
        ),
      ),
    );
  }
}