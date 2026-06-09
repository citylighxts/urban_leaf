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

  Map<String, dynamic> toMap() => {
        'plantId': plantId,
        'plantName': plantName,
        'plantEmoji': plantEmoji,
        'diseaseName': diseaseName,
        'diseaseNameEn': diseaseNameEn,
        'severity': severity.name,
        'diagnosisStatus': diagnosisStatus.name,
        'confidence': confidence,
        'description': description,
        'solutions': solutions,
        'preventionTips': preventionTips,
        'diagnosedAt': diagnosedAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory DiagnosisModel.fromMap(Map<String, dynamic> map, String id) => DiagnosisModel(
        id: id,
        plantId: map['plantId'] as String,
        plantName: map['plantName'] as String,
        plantEmoji: map['plantEmoji'] as String,
        diseaseName: map['diseaseName'] as String,
        diseaseNameEn: map['diseaseNameEn'] as String,
        severity: DiseaseSeverity.values.firstWhere((e) => e.name == map['severity']),
        diagnosisStatus: DiagnosisStatus.values.firstWhere(
            (e) => e.name == map['diagnosisStatus']),
        confidence: (map['confidence'] as num).toDouble(),
        description: map['description'] as String,
        solutions: List<String>.from(map['solutions'] as List),
        preventionTips: List<String>.from(map['preventionTips'] as List),
        diagnosedAt: DateTime.parse(map['diagnosedAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );
}
