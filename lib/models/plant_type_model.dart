class PlantTypeModel {
  final String id;
  final String name;
  final String emoji;
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;
  // Science-backed agronomic data for education features
  final List<int> bestMonths;      // 1–12, optimal planting months for Indonesian climate
  final String plantingTip;        // short tip shown in calendar view
  final String difficulty;         // 'Mudah' | 'Sedang' | 'Sulit'
  final List<String> benefits;     // benefit tags shown in recommendation card
  final String reason;             // why this plant suits its optimal conditions

  const PlantTypeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.minTemp,
    required this.maxTemp,
    required this.minHumidity,
    required this.maxHumidity,
    this.bestMonths = const [],
    this.plantingTip = '',
    this.difficulty = 'Sedang',
    this.benefits = const [],
    this.reason = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'minHumidity': minHumidity,
        'maxHumidity': maxHumidity,
        'bestMonths': bestMonths,
        'plantingTip': plantingTip,
        'difficulty': difficulty,
        'benefits': benefits,
        'reason': reason,
      };

  factory PlantTypeModel.fromMap(Map<String, dynamic> map) => PlantTypeModel(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        minTemp: (map['minTemp'] as num).toDouble(),
        maxTemp: (map['maxTemp'] as num).toDouble(),
        minHumidity: (map['minHumidity'] as num).toDouble(),
        maxHumidity: (map['maxHumidity'] as num).toDouble(),
        bestMonths: (map['bestMonths'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        plantingTip: map['plantingTip'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? 'Sedang',
        benefits: (map['benefits'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        reason: map['reason'] as String? ?? '',
      );
}
