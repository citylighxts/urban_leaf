class PlantTypeModel {
  final String id;
  final String name;
  final String emoji;
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;

  const PlantTypeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.minTemp,
    required this.maxTemp,
    required this.minHumidity,
    required this.maxHumidity,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'minHumidity': minHumidity,
        'maxHumidity': maxHumidity,
      };

  factory PlantTypeModel.fromMap(Map<String, dynamic> map) => PlantTypeModel(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        minTemp: (map['minTemp'] as num).toDouble(),
        maxTemp: (map['maxTemp'] as num).toDouble(),
        minHumidity: (map['minHumidity'] as num).toDouble(),
        maxHumidity: (map['maxHumidity'] as num).toDouble(),
      );
}
