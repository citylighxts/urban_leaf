import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urban_leaf/models/diagnosis_model.dart';

enum PlantStatus { healthy, needsAttention, quarantine }
enum GrowingMethod { soil, hydroponic, aeroponic, container }

class PlantModel {
  final String id;
  final String name;
  final String type;
  final String emoji;
  final GrowingMethod method;
  final DateTime plantedDate;
  final String location;
  final PlantStatus status;
  final PlantStatus? previousStatus;
  final DateTime nextWatering;
  final DateTime? lastWateredAt;
  final String? lastDiagnosis;
  final List<String> careHistory;
  final List<String> diseaseHistory;
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;
  final String notes;

  const PlantModel({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    required this.method,
    required this.plantedDate,
    required this.location,
    required this.status,
    this.previousStatus,
    required this.nextWatering,
    this.lastWateredAt,
    this.lastDiagnosis,
    this.careHistory = const [],
    this.diseaseHistory = const [],
    this.minTemp = 15,
    this.maxTemp = 30,
    this.minHumidity = 40,
    this.maxHumidity = 80,
    this.notes = '',
  });

  String get statusLabel {
    switch (status) {
      case PlantStatus.healthy:
        return 'Sehat';
      case PlantStatus.needsAttention:
        return 'Perlu Perhatian';
      case PlantStatus.quarantine:
        return 'Karantina';
    }
  }

  String get methodLabel {
    switch (method) {
      case GrowingMethod.soil:
        return 'Media Tanah';
      case GrowingMethod.hydroponic:
        return 'Hidroponik';
      case GrowingMethod.aeroponic:
        return 'Aeroponik';
      case GrowingMethod.container:
        return 'Pot / Kontainer';
    }
  }

  int get ageInDays => DateTime.now().difference(plantedDate).inDays;

  bool get isWateringDue =>
      nextWatering.isBefore(DateTime.now()) ||
      nextWatering.difference(DateTime.now()).inHours < 2;

  String get latestConditionLabel =>
      (lastDiagnosis != null && lastDiagnosis!.trim().isNotEmpty)
      ? lastDiagnosis!.trim()
      : 'Belum ada kondisi terbaru';

  String get lastWateredLabel {
    final wateredAt = lastWateredAt;
    if (wateredAt == null) return 'Belum pernah disiram';

    final day = wateredAt.day.toString().padLeft(2, '0');
    final month = wateredAt.month.toString().padLeft(2, '0');
    final year = wateredAt.year.toString();
    final hour = wateredAt.hour.toString().padLeft(2, '0');
    final minute = wateredAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'emoji': emoji,
      'method': method.name,
      'plantedDate': plantedDate,
      'location': location,
      'status': status.name,
      'previousStatus': previousStatus?.name,
      'nextWatering': nextWatering,
      'lastWateredAt': lastWateredAt,
      'lastDiagnosis': lastDiagnosis,
      'careHistory': careHistory,
      'diseaseHistory': diseaseHistory,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'notes': notes,
    };
  }

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    GrowingMethod parseMethod(dynamic value) {
      switch (value?.toString()) {
        case 'soil':
          return GrowingMethod.soil;
        case 'aeroponic':
          return GrowingMethod.aeroponic;
        case 'container':
          return GrowingMethod.container;
        case 'hydroponic':
        default:
          return GrowingMethod.hydroponic;
      }
    }

    PlantStatus parseStatus(dynamic value) {
      switch (value?.toString()) {
        case 'needsAttention':
          return PlantStatus.needsAttention;
        case 'quarantine':
          return PlantStatus.quarantine;
        case 'healthy':
        default:
          return PlantStatus.healthy;
      }
    }

    return PlantModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '🌱',
      method: parseMethod(map['method']),
      plantedDate: parseDate(map['plantedDate']),
      location: map['location']?.toString() ?? '',
      status: parseStatus(map['status']),
      previousStatus: map['previousStatus'] == null
          ? null
          : parseStatus(map['previousStatus']),
      nextWatering: parseDate(map['nextWatering']),
      lastWateredAt: map['lastWateredAt'] == null
          ? null
          : parseDate(map['lastWateredAt']),
      lastDiagnosis: map['lastDiagnosis']?.toString(),
      careHistory: parseStringList(map['careHistory']),
      diseaseHistory: parseStringList(map['diseaseHistory']),
      minTemp: (map['minTemp'] as num?)?.toDouble() ?? 15,
      maxTemp: (map['maxTemp'] as num?)?.toDouble() ?? 30,
      minHumidity: (map['minHumidity'] as num?)?.toDouble() ?? 40,
      maxHumidity: (map['maxHumidity'] as num?)?.toDouble() ?? 80,
      notes: map['notes']?.toString() ?? '',
    );
  }

  // Tambahkan ini di dalam class PlantModel (bisa di bawah factory fromMap)
  PlantStatus getEffectiveStatus(List<DiagnosisModel> diagnoses) {
    if (diagnoses.isEmpty) return status; 

    final sorted = List<DiagnosisModel>.from(diagnoses)
      ..sort((a, b) => b.diagnosedAt.compareTo(a.diagnosedAt));
    final latest = sorted.first;

    // Jika diagnosa terakhir sudah 'resolved', kembalikan ke status asli (Sehat)
    if (latest.diagnosisStatus == DiagnosisStatus.resolved) {
      return PlantStatus.healthy;
    }

    return switch (latest.diagnosisStatus) {
      DiagnosisStatus.active => PlantStatus.quarantine,
      DiagnosisStatus.recovering => PlantStatus.needsAttention,
      DiagnosisStatus.resolved => PlantStatus.healthy,
    };
  }

  PlantModel copyWith({
    String? id,
    String? name,
    String? location,
    PlantStatus? status,
    PlantStatus? previousStatus,
    DateTime? nextWatering,
    DateTime? lastWateredAt,
    String? lastDiagnosis,
    List<String>? careHistory,
    List<String>? diseaseHistory,
    String? notes,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type,
      emoji: emoji,
      method: method,
      plantedDate: plantedDate,
      location: location ?? this.location,
      status: status ?? this.status,
      previousStatus: previousStatus ?? this.previousStatus,
      nextWatering: nextWatering ?? this.nextWatering,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      lastDiagnosis: lastDiagnosis ?? this.lastDiagnosis,
      careHistory: careHistory ?? this.careHistory,
      diseaseHistory: diseaseHistory ?? this.diseaseHistory,
      minTemp: minTemp,
      maxTemp: maxTemp,
      minHumidity: minHumidity,
      maxHumidity: maxHumidity,
      notes: notes ?? this.notes,
    );
  }
}
