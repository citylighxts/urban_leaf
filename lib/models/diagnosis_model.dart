enum DiseaseSeverity { mild, moderate, severe }
enum DiagnosisStatus { active, recovering, resolved }

class DiagnosisModel {
  final String id;
  final String plantId;
  final String plantName;
  final String plantEmoji;
  final String diseaseName;
  final String diseaseNameEn;
  final DiseaseSeverity severity;
  final DiagnosisStatus diagnosisStatus;
  final double confidence;
  final String description;
  final List<String> solutions;
  final List<String> preventionTips;
  final DateTime diagnosedAt;
  final DateTime? updatedAt;

  const DiagnosisModel({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.plantEmoji,
    required this.diseaseName,
    required this.diseaseNameEn,
    required this.severity,
    required this.diagnosisStatus,
    required this.confidence,
    required this.description,
    required this.solutions,
    required this.preventionTips,
    required this.diagnosedAt,
    this.updatedAt,
  });

  String get severityLabel {
    switch (severity) {
      case DiseaseSeverity.mild:
        return 'Ringan';
      case DiseaseSeverity.moderate:
        return 'Sedang';
      case DiseaseSeverity.severe:
        return 'Parah';
    }
  }

  String get statusLabel {
    switch (diagnosisStatus) {
      case DiagnosisStatus.active:
        return 'Aktif';
      case DiagnosisStatus.recovering:
        return 'Membaik';
      case DiagnosisStatus.resolved:
        return 'Sembuh';
    }
  }

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(0)}%';

  DiagnosisModel copyWith({DiagnosisStatus? diagnosisStatus, DateTime? updatedAt}) {
    return DiagnosisModel(
      id: id,
      plantId: plantId,
      plantName: plantName,
      plantEmoji: plantEmoji,
      diseaseName: diseaseName,
      diseaseNameEn: diseaseNameEn,
      severity: severity,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      confidence: confidence,
      description: description,
      solutions: solutions,
      preventionTips: preventionTips,
      diagnosedAt: diagnosedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
