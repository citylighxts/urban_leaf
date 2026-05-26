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
  final DateTime nextWatering;
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
    required this.nextWatering,
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

  int get ageInDays =>
      DateTime.now().difference(plantedDate).inDays;

  bool get isWateringDue =>
      nextWatering.isBefore(DateTime.now()) ||
      nextWatering.difference(DateTime.now()).inHours < 2;

  PlantModel copyWith({
    String? name,
    String? location,
    PlantStatus? status,
    DateTime? nextWatering,
    String? lastDiagnosis,
    List<String>? careHistory,
    List<String>? diseaseHistory,
    String? notes,
  }) {
    return PlantModel(
      id: id,
      name: name ?? this.name,
      type: type,
      emoji: emoji,
      method: method,
      plantedDate: plantedDate,
      location: location ?? this.location,
      status: status ?? this.status,
      nextWatering: nextWatering ?? this.nextWatering,
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
