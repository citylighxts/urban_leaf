import '../../models/alert_model.dart';
import '../../models/plant_model.dart';
import '../../models/weather_model.dart';

class AlertGeneratorResult {
  final List<AlertModel> alerts;
  /// IDs of healthy plants whose conditions now exceed their tolerance.
  final List<String> plantIdsToFlag;

  const AlertGeneratorResult({required this.alerts, required this.plantIdsToFlag});
}

/// Auto-generates smart alerts from real weather data + plant list.
class AlertGeneratorService {
  static AlertGeneratorResult generate({
    required WeatherModel weather,
    required List<ForecastDayModel> forecast,
    required List<PlantModel> plants,
  }) {
    final alerts = <AlertModel>[];
    final now = DateTime.now();

    if (plants.isEmpty) {
      return AlertGeneratorResult(alerts: alerts, plantIdsToFlag: []);
    }

    // Tanaman yang ada di teras/outdoor untuk konteks pesan
    final outdoorPlants = plants
        .where((p) =>
            p.location.toLowerCase().contains('teras') ||
            p.location.toLowerCase().contains('balkon') ||
            p.location.toLowerCase().contains('outdoor'))
        .toList();
    final outdoorLabel = outdoorPlants.isNotEmpty
        ? outdoorPlants.map((p) => p.name).join(', ')
        : plants.map((p) => p.name).join(', ');
    final outdoorEmoji =
        outdoorPlants.isNotEmpty ? outdoorPlants.first.emoji : plants.first.emoji;

    // ── 1. Heat Stress ────────────────────────────────────────────────────
    if (weather.temperature >= 32) {
      final affectedPlants = plants
          .where((p) => weather.temperature > p.maxTemp)
          .toList();
      final candidatePlants = affectedPlants.isNotEmpty ? affectedPlants : outdoorPlants;
      if (candidatePlants.isNotEmpty) {
        final severity =
            weather.temperature >= 36 ? AlertSeverity.critical : AlertSeverity.high;
        final plantLabel = candidatePlants.map((p) => p.name).join(', ');
        final plantEmoji = candidatePlants.first.emoji;

        alerts.add(AlertModel(
          id: 'auto_heat_${now.millisecondsSinceEpoch}',
          type: AlertType.heatStress,
          severity: severity,
          title: 'Heat Stress - Suhu ${weather.temperature.toStringAsFixed(0)}°C',
          description:
              'Suhu hari ini mencapai ${weather.temperature.toStringAsFixed(0)}°C '
              '(terasa ${weather.feelsLike.toStringAsFixed(0)}°C). '
              '$plantLabel berisiko mengalami heat stress dan layu.',
          plantName: plantLabel,
          plantEmoji: plantEmoji,
          status: AlertStatus.active,
          createdAt: now,
          actionRequired:
              'Pindahkan tanaman ke tempat teduh antara pukul 10:00–15:00. '
              'Tingkatkan frekuensi penyiraman di pagi hari.',
        ));
      }
    }

    // ── 2. Fungus Risk ────────────────────────────────────────────────────
    final nextDayRainProb = forecast.length > 1
        ? forecast[1].rainProbability
        : weather.rainProbability;
    if (weather.humidity >= 80 && nextDayRainProb >= 60) {
      final susceptiblePlants = plants
          .where((p) =>
              p.type.toLowerCase().contains('tomat') ||
              p.type.toLowerCase().contains('cabai') ||
              p.status == PlantStatus.quarantine)
          .toList();
      final candidatePlants = susceptiblePlants.isNotEmpty ? susceptiblePlants : outdoorPlants;
      if (candidatePlants.isNotEmpty) {
        final severity = weather.humidity >= 90
            ? AlertSeverity.critical
            : AlertSeverity.high;
        final plantLabel = candidatePlants.map((p) => p.name).join(', ');
        final plantEmoji = candidatePlants.first.emoji;

        alerts.add(AlertModel(
          id: 'auto_fungus_${now.millisecondsSinceEpoch}',
          type: AlertType.fungusRisk,
          severity: severity,
          title:
              'Risiko Jamur Tinggi - Kelembapan ${weather.humidity.toStringAsFixed(0)}%',
          description:
              'Kelembapan udara mencapai ${weather.humidity.toStringAsFixed(0)}% '
              'dan probabilitas hujan esok hari ${nextDayRainProb.toStringAsFixed(0)}%. '
              'Kondisi ini memicu pertumbuhan jamur pada $plantLabel.',
          plantName: plantLabel,
          plantEmoji: plantEmoji,
          status: AlertStatus.active,
          createdAt: now,
          actionRequired:
              'Tingkatkan ventilasi, hindari penyiraman daun, '
              'aplikasikan fungisida preventif berbasis tembaga.',
        ));
      }
    }

    // ── 3. UV Index Tinggi ────────────────────────────────────────────────
    if (weather.uvIndex >= 7 && outdoorPlants.isNotEmpty) {
      final severity =
          weather.uvIndex >= 10 ? AlertSeverity.critical : AlertSeverity.medium;

      alerts.add(AlertModel(
        id: 'auto_uv_${now.millisecondsSinceEpoch}',
        type: AlertType.uvHigh,
        severity: severity,
        title:
            'UV Index ${weather.uvIndex.toStringAsFixed(1)} - ${weather.uvLabel}',
        description:
            'UV Index mencapai ${weather.uvIndex.toStringAsFixed(1)} (${weather.uvLabel}) '
            'antara pukul 10:00–14:00. '
            '$outdoorLabel rentan mengalami sunburn pada daun.',
        plantName: outdoorLabel,
        plantEmoji: outdoorEmoji,
        status: AlertStatus.active,
        createdAt: now,
        actionRequired:
            'Pasang paranet atau shade cloth 30–50% selama jam puncak UV. '
            'Hindari memindahkan tanaman saat siang.',
      ));
    }

    // ── 4. Hujan Lebat (prediksi) ─────────────────────────────────────────
    final heavyRainDay = forecast.where((f) =>
        f.precipitation >= 15 && f.rainProbability >= 70).toList();
    if (heavyRainDay.isNotEmpty && outdoorPlants.isNotEmpty) {
      final days = heavyRainDay.length;
      alerts.add(AlertModel(
        id: 'auto_rain_${now.millisecondsSinceEpoch}',
        type: AlertType.heavyRain,
        severity: AlertSeverity.medium,
        title:
            'Hujan Lebat Diprediksi - ${heavyRainDay.first.precipitation.toStringAsFixed(0)}mm',
        description:
            'Curah hujan ${heavyRainDay.first.precipitation.toStringAsFixed(0)}mm '
            'diprediksi dalam $days hari ke depan (${heavyRainDay.first.dayLabel}). '
            '$outdoorLabel rentan tergenang.',
        plantName: outdoorLabel,
        plantEmoji: outdoorEmoji,
        status: AlertStatus.active,
        createdAt: now,
        actionRequired:
            'Pastikan drainase pot baik. Pindahkan tanaman sensitif ke dalam. '
            'Kurangi jadwal penyiraman manual.',
      ));
    }

    // ── 5. Kekeringan ─────────────────────────────────────────────────────
    final dryDays = forecast
        .where((f) => f.rainProbability < 15 && f.precipitation < 1)
        .length;
    if (dryDays >= 3 && weather.humidity < 45) {
      final droopyPlants = plants
          .where((p) => weather.humidity < p.minHumidity)
          .toList();
      final candidatePlants = droopyPlants.isNotEmpty ? droopyPlants : outdoorPlants;
      if (candidatePlants.isNotEmpty) {
        final plantLabel = candidatePlants.map((p) => p.name).join(', ');
        final plantEmoji = candidatePlants.first.emoji;

        alerts.add(AlertModel(
          id: 'auto_drought_${now.millisecondsSinceEpoch}',
          type: AlertType.drought,
          severity: AlertSeverity.medium,
          title: 'Risiko Kekeringan - $dryDays Hari Tanpa Hujan',
          description:
              'Tidak ada hujan diprediksi selama $dryDays hari ke depan '
              'dengan kelembapan ${weather.humidity.toStringAsFixed(0)}%. '
              '$plantLabel berisiko kekurangan air.',
          plantName: plantLabel,
          plantEmoji: plantEmoji,
          status: AlertStatus.active,
          createdAt: now,
          actionRequired:
              'Tingkatkan frekuensi penyiraman di pagi dan sore hari. '
              'Gunakan mulsa untuk menjaga kelembapan tanah.',
        ));
      }
    }

    // ── 6. Per-plant tolerance check ─────────────────────────────────────
    // Only flags healthy plants - quarantine/needsAttention are already known.
    final plantIdsToFlag = <String>[];
    for (final plant in plants.where((p) => p.status == PlantStatus.healthy)) {
      final tempOut = weather.temperature < plant.minTemp || weather.temperature > plant.maxTemp;
      final humOut  = weather.humidity < plant.minHumidity || weather.humidity > plant.maxHumidity;
      if (!tempOut && !humOut) continue;

      plantIdsToFlag.add(plant.id);

      final issues = <String>[];
      if (tempOut) {
        issues.add(
          weather.temperature > plant.maxTemp
              ? 'suhu ${weather.temperature.toStringAsFixed(0)}°C (maks ${plant.maxTemp.toStringAsFixed(0)}°C)'
              : 'suhu ${weather.temperature.toStringAsFixed(0)}°C (min ${plant.minTemp.toStringAsFixed(0)}°C)',
        );
      }
      if (humOut) {
        issues.add(
          weather.humidity > plant.maxHumidity
              ? 'kelembapan ${weather.humidity.toStringAsFixed(0)}% (maks ${plant.maxHumidity.toStringAsFixed(0)}%)'
              : 'kelembapan ${weather.humidity.toStringAsFixed(0)}% (min ${plant.minHumidity.toStringAsFixed(0)}%)',
        );
      }

      alerts.add(AlertModel(
        id: 'tolerance_${plant.id}_${now.millisecondsSinceEpoch}',
        type: AlertType.toleranceExceeded,
        severity: AlertSeverity.high,
        title: '${plant.emoji} ${plant.name} - Kondisi di Luar Toleransi',
        description:
            '${plant.name} mengalami ${issues.join(' dan ')} '
            'yang melebihi batas toleransinya.',
        plantName: plant.name,
        plantEmoji: plant.emoji,
        status: AlertStatus.active,
        createdAt: now,
        actionRequired:
            'Periksa kondisi ${plant.name} dan pertimbangkan untuk '
            'memindahkan atau memberikan perlindungan tambahan.',
      ));
    }

    return AlertGeneratorResult(alerts: alerts, plantIdsToFlag: plantIdsToFlag);
  }
}
