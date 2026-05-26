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

  String get dayLabel {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }
}
