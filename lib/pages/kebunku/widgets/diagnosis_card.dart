import 'package:flutter/material.dart';
import 'package:urban_leaf/models/diagnosis_model.dart';
import 'package:urban_leaf/services/diagnosis_firestore_service.dart';
import 'package:urban_leaf/core/theme/app_colors.dart';
import 'package:urban_leaf/core/theme/app_text_styles.dart';
import 'package:urban_leaf/services/plant_firestore_service.dart';
import '../../ai_scanner/manual_diagnosis_page.dart';
import 'dart:io';
import '../../ai_scanner/ai_scanner_page.dart'; // Sesuaikan path-nya

class DiagnosisCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final DiagnosisFirestoreService diagnosisService;

  const DiagnosisCard({
    super.key,
    required this.diagnosis,
    required this.diagnosisService,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // <--- BUNGKUS DENGAN INKWELL
      borderRadius: BorderRadius.circular(14),
      onTap: () {

        // DEBUG: GAMBAR
        final file = (diagnosis.imagePath != null && diagnosis.imagePath!.isNotEmpty) 
               ? File(diagnosis.imagePath!) 
               : null;
  
        // DEBUGGING: Cek di terminal apakah file benar-benar ditemukan
        if (file != null) {
          print("DEBUG: Cek path: ${file.path}");
          print("DEBUG: Apakah file ada? ${file.existsSync()}");
        } else {
          print("DEBUG: Path gambar kosong di Firestore");
        }

        // Navigasi ke halaman detail hasil (bisa digunakan untuk AI maupun Manual)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              body: DiagnosisResult(
                diagnosis: diagnosis,
                onRescan: () => Navigator.pop(context),
                firestoreService: PlantFirestoreService(), imageFile: null, 
              ),
            ),
          ),
        );
      },
      child: Container( // <--- INI KONTEN KARTU KAMU
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8F0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diagnosis.statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(diagnosis.confidence * 100).toStringAsFixed(0)}% akurat',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(diagnosis.diseaseName, style: AppTextStyles.headingSmall),
            const SizedBox(height: 2),
            Text(
              diagnosis.diseaseNameEn,
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(diagnosis.description, style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            const Text('Solusi:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 6),
            ...diagnosis.solutions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: AppTextStyles.bodySmall),
                    Expanded(child: Text(s, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Didiagnosis: ${_formatDate(diagnosis.diagnosedAt)}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusDropdown(
                    current: diagnosis.diagnosisStatus,
                    onChanged: (status) => diagnosisService
                        .updateStatus(diagnosis.id, status, diagnosis.plantId)
                        .catchError((_) {}),
                  ),
                ),
                const SizedBox(width: 8),
                
                if (diagnosis.isManual) 
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    tooltip: 'Edit diagnosa',
                    onPressed: () {
                      // Navigasi ke halaman edit
                      // Pastikan Anda sudah mengimport 'dart:io' untuk File
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManualDiagnosisPage(
                            imageFile: diagnosis.imagePath != null &&
                                    diagnosis.imagePath!.isNotEmpty
                                ? File(diagnosis.imagePath!)
                                : null,
                            isEditMode: true,
                            diagnosisToEdit: diagnosis,
                          ),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                const SizedBox(width: 8),


                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger, size: 20),
                  tooltip: 'Hapus diagnosis',
                  onPressed: () =>
                      diagnosisService
                        .deleteDiagnosis(diagnosis.id, diagnosis.plantId)
                        .catchError((_) {}),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

extension _DiagnosisStatusLabel on DiagnosisStatus {
  String get statusLabel => switch (this) {
        DiagnosisStatus.active => 'Aktif',
        DiagnosisStatus.recovering => 'Membaik',
        DiagnosisStatus.resolved => 'Sembuh',
      };
}

class _StatusDropdown extends StatelessWidget {
  final DiagnosisStatus current;
  final ValueChanged<DiagnosisStatus> onChanged;

  const _StatusDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DiagnosisStatus>(
      initialValue: current,
      isDense: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
        ),
      ),
      items: DiagnosisStatus.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.statusLabel, style: AppTextStyles.bodySmall)))
          .toList(),
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }
}


  