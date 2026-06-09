class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double uvIndex;
  final double precipitation;
  final double rainProbability;
  final String condition;
  final String conditionEmoji;
  final String location;
  final DateTime lastUpdated;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.uvIndex,
    required this.precipitation,
    required this.rainProbability,
    required this.condition,
    required this.conditionEmoji,
    required this.location,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'uvIndex': uvIndex,
        'precipitation': precipitation,
        'rainProbability': rainProbability,
        'condition': condition,
        'conditionEmoji': conditionEmoji,
        'location': location,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
        temperature: (json['temperature'] as num).toDouble(),
        feelsLike: (json['feelsLike'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        uvIndex: (json['uvIndex'] as num).toDouble(),
        precipitation: (json['precipitation'] as num).toDouble(),
        rainProbability: (json['rainProbability'] as num).toDouble(),
        condition: json['condition'] as String,
        conditionEmoji: json['conditionEmoji'] as String,
        location: json['location'] as String,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  String get lastUpdatedLabel {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    return '${diff.inHours} jam lalu';
  }

  String get uvLabel {
    if (uvIndex < 3) return 'Rendah';
    if (uvIndex < 6) return 'Sedang';
    if (uvIndex < 8) return 'Tinggi';
    if (uvIndex < 11) return 'Sangat Tinggi';
    return 'Ekstrem';
  }
}

class ForecastDayModel {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double rainProbability;
  final double precipitation;
  final String condition;
  final String conditionEmoji;
  final double uvIndex;

  const ForecastDayModel({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.precipitation,
    required this.condition,
    required this.conditionEmoji,
    required this.uvIndex,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'rainProbability': rainProbability,
        'precipitation': precipitation,
        'condition': condition,
        'conditionEmoji': conditionEmoji,
        'uvIndex': uvIndex,
      };

  factory ForecastDayModel.fromJson(Map<String, dynamic> json) =>
      ForecastDayModel(
        date: DateTime.parse(json['date'] as String),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        minTemp: (json['minTemp'] as num).toDouble(),
        rainProbability: (json['rainProbability'] as num).toDouble(),
        precipitation: (json['precipitation'] as num).toDouble(),
        condition: json['condition'] as String,
        conditionEmoji: json['conditionEmoji'] as String,
        uvIndex: (json['uvIndex'] as num).toDouble(),
      );

  String get dayLabel {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }
}
