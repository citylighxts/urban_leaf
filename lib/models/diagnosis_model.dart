import 'package:cloud_firestore/cloud_firestore.dart';

// enum DiseaseSeverity { mild, moderate, severe }
enum DiagnosisStatus { active, recovering, resolved }

class DiagnosisModel {
  final String id;
  final String plantId;
  final String plantName;
  final String plantEmoji;
  final String diseaseName;
  final String diseaseNameEn;
  final DiagnosisStatus diagnosisStatus;
  final double confidence;
  final String description;
  final List<String> solutions;
  final List<String> preventionTips;
  final DateTime diagnosedAt;
  final DateTime? updatedAt;
  final String? imagePath; 
  final bool isManual;

  const DiagnosisModel({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.plantEmoji,
    required this.diseaseName,
    required this.diseaseNameEn,
    required this.diagnosisStatus,
    required this.confidence,
    required this.description,
    required this.solutions,
    required this.preventionTips,
    required this.diagnosedAt,
    this.updatedAt,
    this.imagePath,        
    this.isManual = false,
  });

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

  DiagnosisModel copyWith({DiagnosisStatus? diagnosisStatus, DateTime? updatedAt, String? imagePath, required String diseaseName, required String description, required List<String> solutions,}) {
    return DiagnosisModel(
      id: id,
      plantId: plantId,
      plantName: plantName,
      plantEmoji: plantEmoji,
      diseaseName: diseaseName,
      diseaseNameEn: diseaseNameEn,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      confidence: confidence,
      description: description,
      solutions: solutions,
      preventionTips: preventionTips,
      diagnosedAt: diagnosedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath, 
      isManual: isManual,
    );
  }

  Map<String, dynamic> toMap() => {
        'plantId': plantId,
        'plantName': plantName,
        'plantEmoji': plantEmoji,
        'diseaseName': diseaseName,
        'diseaseNameEn': diseaseNameEn,
        'diagnosisStatus': diagnosisStatus.name,
        'confidence': confidence,
        'description': description,
        'solutions': solutions,
        'preventionTips': preventionTips,
        'diagnosedAt': Timestamp.fromDate(diagnosedAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'imagePath': imagePath,
        'isManual': isManual,
      };

  factory DiagnosisModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.whereType().map((e) => e.toString()).toList();
      }
      return const [];
    }

    DiagnosisStatus parseStatus(dynamic value) {
      final raw = value?.toString();
      return DiagnosisStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => DiagnosisStatus.active,
      );
    }

    return DiagnosisModel(
      id: id,
      plantId: map['plantId']?.toString() ?? '',
      plantName: map['plantName']?.toString() ?? '',
      plantEmoji: map['plantEmoji']?.toString() ?? '🌱',
      diseaseName: map['diseaseName']?.toString() ?? '',
      diseaseNameEn: map['diseaseNameEn']?.toString() ?? '',
      diagnosisStatus: parseStatus(map['diagnosisStatus']),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      solutions: parseStringList(map['solutions']),
      preventionTips: parseStringList(map['preventionTips']),
      diagnosedAt: parseDate(map['diagnosedAt']),
      updatedAt: map['updatedAt'] == null ? null : parseDate(map['updatedAt']),
      imagePath: map['imagePath']?.toString(),
      isManual: map['isManual'] is bool ? map['isManual'] as bool : false,
    );
  }
}
