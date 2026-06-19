import 'dart:io';
import 'package:flutter/material.dart';
// import '../../core/theme/app_colors.dart';
import '../../models/diagnosis_model.dart';
import '../../models/plant_model.dart';
import '../../services/diagnosis_firestore_service.dart';
import '../../services/plant_firestore_service.dart';


class ManualDiagnosisPage extends StatefulWidget {
  final File? imageFile;
  final bool isEditMode;
  final DiagnosisModel? diagnosisToEdit;
  const ManualDiagnosisPage({
    super.key,
    this.imageFile,
    this.isEditMode = false,
    this.diagnosisToEdit,
  });

  @override
  State<ManualDiagnosisPage> createState() => _ManualDiagnosisPageState();
}

class _ManualDiagnosisPageState extends State<ManualDiagnosisPage> {
  final _namaPenyakitController = TextEditingController();
  final _gejalaController = TextEditingController();
  final _solusiController = TextEditingController();
  final _diagnosisService = DiagnosisFirestoreService();
  final _plantService = PlantFirestoreService();
  

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi controller otomatis
    if (widget.isEditMode && widget.diagnosisToEdit != null) {
      _namaPenyakitController.text = widget.diagnosisToEdit!.diseaseName;
      _gejalaController.text = widget.diagnosisToEdit!.description;
      _solusiController.text = widget.diagnosisToEdit!.solutions.isNotEmpty 
          ? widget.diagnosisToEdit!.solutions.first : '';
    }
  }
  
  Future<void> _handleUpdate() async {
    final diagnosis = widget.diagnosisToEdit;
    if (diagnosis == null) return;

    final updatedDiagnosis = diagnosis.copyWith(
      diseaseName: _namaPenyakitController.text.trim(),
      description: _gejalaController.text.trim(),
      solutions: _solusiController.text.trim().isEmpty
          ? const []
          : [_solusiController.text.trim()],
    );

    try {
      await _diagnosisService.updateDiagnosis(diagnosis.plantId, updatedDiagnosis);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update diagnosis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showSaveDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2018),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StreamBuilder<List<PlantModel>>(
        stream: _plantService.watchPlants(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final livePlants = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Tanaman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: livePlants.length,
                    itemBuilder: (context, index) {
                      final plant = livePlants[index];
                      return ListTile(
                        leading: Text(
                          plant.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          plant.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          final plantId = plant.id;
                          final diagnosis = DiagnosisModel(
                            id: '',
                            plantId: plant.id,
                            plantName: plant.name,
                            plantEmoji: plant.emoji,
                            diseaseName: _namaPenyakitController.text.trim(),
                            diseaseNameEn: 'Human Diagnose',
                            diagnosisStatus: DiagnosisStatus.active,
                            confidence: 0.0,
                            description: _gejalaController.text.trim(),
                            solutions: _solusiController.text.trim().isEmpty
                                ? const []
                                : [_solusiController.text.trim()],
                            preventionTips: const [],
                            diagnosedAt: DateTime.now(),
                            imagePath: widget.imageFile?.path,
                            isManual: true,
                          );

                          await _diagnosisService.addDiagnosis(plantId, diagnosis);

                          if (!mounted) return;
                          if (context.mounted) Navigator.pop(ctx);
                          if (context.mounted) Navigator.pop(context, true);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.white;
    const inputColor = Color(0xFF0A1A12);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Diagnosa Manual", style: TextStyle(color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.imageFile != null && widget.imageFile!.existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                widget.imageFile!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada gambar preview',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Fungsi builder untuk input agar konsisten
          _buildInputField(controller: _namaPenyakitController, label: "Nama Penyakit", inputColor: inputColor),
          const SizedBox(height: 16),
          _buildInputField(controller: _gejalaController, label: "Gejala Penyakit", inputColor: inputColor),
          const SizedBox(height: 16),
          _buildInputField(controller: _solusiController, label: "Rencana Perawatan", inputColor: inputColor, maxLines: 3),
          
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              if (widget.isEditMode) {
                _handleUpdate();
              } else {
                _showSaveDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1A12), 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              widget.isEditMode ? "Update Diagnosa" : "Simpan ke Tanaman", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),

          const SizedBox(height: 12),

          // 3. Tombol Scan Lagi
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0A1A12), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16), // Samakan tingginya dengan tombol atas
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Scan Lagi", 
              style: TextStyle(color: Color(0xFF0A1A12), fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu agar input rapi dan seragam
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required Color inputColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black), // Teks input user Hitam
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: inputColor.withOpacity(0.7)),
        filled: true,
        fillColor: inputColor.withOpacity(0.05), // Sedikit warna hijau di box
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputColor), // Garis hijau tua
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputColor, width: 2),
        ),
      ),
    );
  }
}