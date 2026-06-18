import '../models/plant_model.dart';
import '../models/weather_model.dart';

class DailyTip {
  final String emoji;
  final String title;
  final String body;
  final TipPriority priority;

  const DailyTip({
    required this.emoji,
    required this.title,
    required this.body,
    required this.priority,
  });
}

enum TipPriority { urgent, normal, info }

class TipGeneratorService {
  /// Generate contextual tips based on current weather, forecast, plants,
  /// and current month. Returns tips sorted by priority (urgent first).
  static List<DailyTip> generate({
    required WeatherModel weather,
    required List<ForecastDayModel> forecast,
    required List<PlantModel> plants,
  }) {
    final tips = <DailyTip>[];
    final month = DateTime.now().month;

    // ── Cuaca hari ini ────────────────────────────────────────────────────────

    if (weather.temperature >= 35) {
      tips.add(const DailyTip(
        emoji: '🌡️',
        title: 'Siaga Panas Ekstrem',
        body:
            'Suhu di atas 35°C hari ini. Siram tanaman sebelum pukul 08.00 atau setelah 16.00. '
            'Pasang shade net untuk selada, bayam, dan pakcoy segera.',
        priority: TipPriority.urgent,
      ));
    } else if (weather.temperature >= 32) {
      tips.add(const DailyTip(
        emoji: '☀️',
        title: 'Hari yang Panas - Pantau Tanamanmu',
        body:
            'Suhu cukup tinggi hari ini. Pastikan media tanam tidak kering total. '
            'Tanaman berdaun tipis seperti selada mungkin perlu naungan ekstra.',
        priority: TipPriority.normal,
      ));
    }

    if (weather.uvIndex >= 8) {
      tips.add(const DailyTip(
        emoji: '🌞',
        title: 'UV Index Sangat Tinggi',
        body:
            'UV hari ini sangat tinggi. Selada dan bayam berisiko leaf scorch. '
            'Pasang shade cloth 30–50% atau pindahkan ke tempat teduh parsial.',
        priority: TipPriority.urgent,
      ));
    } else if (weather.uvIndex >= 6) {
      tips.add(const DailyTip(
        emoji: '🌤️',
        title: 'UV Tinggi - Awasi Daun Tipis',
        body:
            'UV cukup tinggi siang ini. Tanaman herbal dan sayuran daun akan baik-baik saja, '
            'tapi periksa apakah ada tanda daun mengering di tepi.',
        priority: TipPriority.info,
      ));
    }

    if (weather.humidity >= 85) {
      tips.add(const DailyTip(
        emoji: '💦',
        title: 'Kelembapan Sangat Tinggi - Waspada Jamur',
        body:
            'Kelembapan di atas 85% mendorong pertumbuhan jamur. Pastikan sirkulasi udara baik, '
            'kurangi frekuensi penyiraman, dan periksa daun bawah dari tanda awal bercak.',
        priority: TipPriority.urgent,
      ));
    } else if (weather.humidity >= 75) {
      tips.add(const DailyTip(
        emoji: '🌫️',
        title: 'Kelembapan Tinggi',
        body:
            'Kelembapan relatif cukup tinggi. Hindari menyiram daun langsung '
            'dan pastikan ada cukup jarak antar tanaman untuk sirkulasi udara.',
        priority: TipPriority.info,
      ));
    }

    if (weather.rainProbability >= 70) {
      tips.add(const DailyTip(
        emoji: '🌧️',
        title: 'Peluang Hujan Tinggi Hari Ini',
        body:
            'Kemungkinan hujan besar hari ini. Periksa drainase semua pot. '
            'Jika punya tanaman tomat atau cabai, pertimbangkan pasang atap plastik sementara.',
        priority: TipPriority.normal,
      ));
    }

    if (weather.precipitation > 0 && weather.precipitation < 5) {
      tips.add(const DailyTip(
        emoji: '🌦️',
        title: 'Gerimis - Kurangi Penyiraman',
        body:
            'Ada presipitasi ringan hari ini. Kamu bisa skip penyiraman pagi - '
            'tanah sudah mendapat cukup air dari gerimis.',
        priority: TipPriority.info,
      ));
    }

    // ── Forecast minggu depan ──────────────────────────────────────────────────

    if (forecast.isNotEmpty) {
      final avgRainNext3 = forecast
              .take(3)
              .map((f) => f.rainProbability)
              .reduce((a, b) => a + b) /
          3;
      final avgMaxNext3 =
          forecast.take(3).map((f) => f.maxTemp).reduce((a, b) => a + b) / 3;

      if (avgRainNext3 >= 65) {
        tips.add(const DailyTip(
          emoji: '⛈️',
          title: 'Siapkan Kebun untuk Hujan 3 Hari ke Depan',
          body:
              'Prakiraan hujan tinggi 3 hari ke depan. Sekarang waktu yang tepat untuk '
              'memeriksa lubang drainase pot dan memastikan tidak ada genangan di sekitar area tanam.',
          priority: TipPriority.normal,
        ));
      }

      if (avgMaxNext3 >= 34) {
        tips.add(const DailyTip(
          emoji: '🔥',
          title: 'Gelombang Panas di Depan',
          body:
              'Suhu maksimal diperkirakan di atas 34°C beberapa hari ke depan. '
              'Siapkan shade net dan stok mulsa sekarang sebelum terlambat.',
          priority: TipPriority.normal,
        ));
      }
    }

    // ── Kondisi tanaman milik user ─────────────────────────────────────────────

    final needsWatering =
        plants.where((p) => p.isWateringDue).toList();
    if (needsWatering.isNotEmpty) {
      final names = needsWatering.take(3).map((p) => p.name).join(', ');
      final more =
          needsWatering.length > 3 ? ' +${needsWatering.length - 3} lainnya' : '';
      tips.add(DailyTip(
        emoji: '💧',
        title: 'Waktunya Menyiram',
        body: '$names$more sudah waktunya disiram hari ini. Siram pagi ini sebelum panas.',
        priority: TipPriority.urgent,
      ));
    }

    final sickPlants =
        plants.where((p) => p.status == PlantStatus.quarantine).toList();
    if (sickPlants.isNotEmpty) {
      tips.add(DailyTip(
        emoji: '🏥',
        title: '${sickPlants.length} Tanaman dalam Karantina',
        body:
            'Periksa tanaman dalam karantina hari ini. Isolasi dari tanaman sehat '
            'dan lanjutkan penanganan. Jangan lupa sterilkan alat berkebunmu.',
        priority: TipPriority.urgent,
      ));
    }

    final heatSensitivePlants = plants.where((p) =>
        p.maxTemp < weather.temperature &&
        p.status == PlantStatus.healthy).toList();
    if (heatSensitivePlants.isNotEmpty && weather.temperature >= 30) {
      final names =
          heatSensitivePlants.take(2).map((p) => p.name).join(' dan ');
      tips.add(DailyTip(
        emoji: '🌡️',
        title: 'Tanaman Sensitif Panas di Kebunmu',
        body:
            '$names berada di atas suhu toleransinya hari ini. Pertimbangkan pindah ke lokasi lebih teduh sementara.',
        priority: TipPriority.normal,
      ));
    }

    final highHumidityRisk = weather.humidity >= 80 &&
        plants.any((p) => ['Tomat', 'Cabai', 'Paprika', 'Stroberi']
            .any((name) => p.name.contains(name) || p.type.contains(name)));
    if (highHumidityRisk) {
      tips.add(const DailyTip(
        emoji: '🍄',
        title: 'Risiko Jamur pada Tanaman Buahmu',
        body:
            'Kelembapan tinggi hari ini berisiko memicu Early Blight atau Powdery Mildew '
            'pada tomat, cabai, atau stroberi. Periksa daun bawah dan tingkatkan sirkulasi udara.',
        priority: TipPriority.normal,
      ));
    }

    // ── Tips musiman ───────────────────────────────────────────────────────────

    if ([6, 7, 8, 9].contains(month)) {
      // Musim kemarau
      tips.add(const DailyTip(
        emoji: '🌾',
        title: 'Tip Musim Kemarau',
        body:
            'Musim kemarau adalah waktu terbaik menanam tomat, cabai, dan terong. '
            'Tambahkan lapisan mulsa organik untuk mengurangi penguapan air.',
        priority: TipPriority.info,
      ));
    } else if ([11, 12, 1, 2].contains(month)) {
      // Musim hujan puncak
      tips.add(const DailyTip(
        emoji: '🌱',
        title: 'Tip Musim Hujan',
        body:
            'Musim hujan ideal untuk sayuran daun seperti kangkung, bayam, dan pakcoy. '
            'Kurangi frekuensi penyiraman dan pastikan drainase lancar.',
        priority: TipPriority.info,
      ));
    } else if ([3, 4, 5].contains(month)) {
      // Peralihan hujan → kemarau
      tips.add(const DailyTip(
        emoji: '🔄',
        title: 'Musim Peralihan - Waspada Cuaca Tidak Menentu',
        body:
            'Cuaca di bulan ini tidak menentu - bisa panas ekstrem lalu hujan deras. '
            'Pantau cuaca lebih sering dan jangan terlalu agresif dalam pemupukan.',
        priority: TipPriority.info,
      ));
    } else if ([10].contains(month)) {
      // Peralihan kemarau → hujan
      tips.add(const DailyTip(
        emoji: '🌥️',
        title: 'Awal Musim Hujan - Saatnya Semai',
        body:
            'Awal musim hujan adalah waktu terbaik untuk semai benih sayuran daun. '
            'Curah hujan akan membantu pertumbuhan awal tanpa banyak penyiraman manual.',
        priority: TipPriority.info,
      ));
    }

    // ── Fallback jika tidak ada kondisi khusus ─────────────────────────────────

    if (tips.isEmpty) {
      tips.add(DailyTip(
        emoji: '✅',
        title: 'Kondisi Berkebun Ideal Hari Ini',
        body:
            'Cuaca hari ini ideal untuk berkebun - suhu ${weather.temperature.toStringAsFixed(0)}°C '
            'dengan kelembapan ${weather.humidity.toStringAsFixed(0)}%. '
            'Waktu yang bagus untuk semai benih baru atau memindahkan bibit.',
        priority: TipPriority.info,
      ));
    }

    // Sort: urgent dulu, lalu normal, lalu info
    tips.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return tips;
  }
}
