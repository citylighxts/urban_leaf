import 'package:flutter/material.dart';
import '../../../models/diagnosis_model.dart';
import '../../../models/plant_model.dart';
import '../../../services/diagnosis_firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../ai_scanner/manual_diagnosis_page.dart';
import 'dart:io'; 

class DiagnosisStreamTab extends StatelessWidget {
  final Stream<List<DiagnosisModel>> stream;
  final DiagnosisFirestoreService diagnosisService;
  final PlantModel plant;

  const DiagnosisStreamTab({
    super.key,
    required this.stream,
    required this.diagnosisService,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiagnosisModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("=== DIAGNOSIS ERROR ===");
          print(snapshot.error);

          return Center(
            child: Text(
              'Gagal memuat riwayat penyakit\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.danger),
            ),
          );
        }

        return _DiagnosisTab(
          diagnoses: snapshot.data ?? [],
          plant: plant,
          diagnosisService: diagnosisService,
        );
      },
    );
  }
}

class _DiagnosisTab extends StatelessWidget {
  final List<DiagnosisModel> diagnoses;
  final PlantModel plant;
  final DiagnosisFirestoreService diagnosisService;

  const _DiagnosisTab({
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
      itemBuilder: (context, index) => _DiagnosisCard(
        diagnosis: diagnoses[index],
        diagnosisService: diagnosisService,
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final DiagnosisFirestoreService diagnosisService;

  const _DiagnosisCard({
    required this.diagnosis,
    required this.diagnosisService,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
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
                      .updateStatus(diagnosis.id, status)
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
                          imageFile: File(diagnosis.imagePath ?? ''),
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
                    diagnosisService.deleteDiagnosis(diagnosis.id).catchError((_) {}),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
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
