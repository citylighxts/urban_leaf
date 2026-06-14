import '../../models/alert_model.dart';
import '../../models/article_model.dart';
import '../../models/diagnosis_model.dart';
import '../../models/plant_model.dart';
import '../../models/weather_model.dart';

class DummyData {
  // ─── Weather ──────────────────────────────────────────────────────────────

  static final WeatherModel currentWeather = WeatherModel(
    temperature: 34.0,
    feelsLike: 37.5,
    humidity: 78,
    uvIndex: 8.2,
    precipitation: 0.0,
    rainProbability: 25,
    condition: 'Cerah Berawan',
    conditionEmoji: '⛅',
    location: 'Kebayoran Baru, Jakarta',
    lastUpdated: DateTime.now(),
  );

  static final List<ForecastDayModel> forecast = [
    ForecastDayModel(
      date: DateTime.now(),
      maxTemp: 34,
      minTemp: 26,
      rainProbability: 25,
      precipitation: 0.0,
      condition: 'Cerah Berawan',
      conditionEmoji: '⛅',
      uvIndex: 8.2,
    ),
    ForecastDayModel(
      date: DateTime.now().add(const Duration(days: 1)),
      maxTemp: 31,
      minTemp: 24,
      rainProbability: 70,
      precipitation: 12.5,
      condition: 'Hujan Ringan',
      conditionEmoji: '🌦️',
      uvIndex: 4.1,
    ),
    ForecastDayModel(
      date: DateTime.now().add(const Duration(days: 2)),
      maxTemp: 29,
      minTemp: 23,
      rainProbability: 85,
      precipitation: 22.0,
      condition: 'Hujan Lebat',
      conditionEmoji: '🌧️',
      uvIndex: 2.8,
    ),
    ForecastDayModel(
      date: DateTime.now().add(const Duration(days: 3)),
      maxTemp: 30,
      minTemp: 24,
      rainProbability: 60,
      precipitation: 8.0,
      condition: 'Hujan Gerimis',
      conditionEmoji: '🌦️',
      uvIndex: 5.5,
    ),
    ForecastDayModel(
      date: DateTime.now().add(const Duration(days: 4)),
      maxTemp: 33,
      minTemp: 25,
      rainProbability: 20,
      precipitation: 0.5,
      condition: 'Cerah',
      conditionEmoji: '☀️',
      uvIndex: 9.0,
    ),
  ];

  // ─── Plants ───────────────────────────────────────────────────────────────

  static final List<PlantModel> plants = [
    PlantModel(
      id: 'p001',
      name: 'Selada Hidroponik A',
      type: 'Selada',
      emoji: '🥬',
      method: GrowingMethod.hydroponic,
      plantedDate: DateTime.now().subtract(const Duration(days: 32)),
      location: 'Balkon Lantai 2',
      status: PlantStatus.needsAttention,
      nextWatering: DateTime.now().subtract(const Duration(hours: 1)),
      lastDiagnosis: null,
      careHistory: [
        'Pemberian nutrisi AB-Mix - 3 hari lalu',
        'Ganti larutan nutrisi - 7 hari lalu',
        'Pemangkasan daun tua - 14 hari lalu',
      ],
      diseaseHistory: [],
      minTemp: 18,
      maxTemp: 28,
      minHumidity: 50,
      maxHumidity: 75,
      notes: 'Pertumbuhan bagus, perlu cek pH larutan.',
    ),
    PlantModel(
      id: 'p002',
      name: 'Tomat Cherry A',
      type: 'Tomat',
      emoji: '🍅',
      method: GrowingMethod.container,
      plantedDate: DateTime.now().subtract(const Duration(days: 58)),
      location: 'Teras Depan',
      status: PlantStatus.quarantine,
      nextWatering: DateTime.now().add(const Duration(hours: 4)),
      lastDiagnosis: 'Early Blight (Alternaria solani)',
      careHistory: [
        'Semprotan fungisida - 2 hari lalu',
        'Pemangkasan daun terinfeksi - 3 hari lalu',
        'Penyiraman rutin - 5 hari lalu',
      ],
      diseaseHistory: [
        'Early Blight - terdeteksi 3 hari lalu',
      ],
      minTemp: 20,
      maxTemp: 32,
      minHumidity: 45,
      maxHumidity: 70,
      notes: 'Karantina karena Early Blight. Pantau perkembangan.',
    ),
    PlantModel(
      id: 'p003',
      name: 'Cabai Rawit B',
      type: 'Cabai',
      emoji: '🌶️',
      method: GrowingMethod.container,
      plantedDate: DateTime.now().subtract(const Duration(days: 45)),
      location: 'Jendela Dapur',
      status: PlantStatus.healthy,
      nextWatering: DateTime.now().add(const Duration(hours: 8)),
      careHistory: [
        'Pemupukan NPK - 5 hari lalu',
        'Penyiraman rutin - 2 hari lalu',
      ],
      diseaseHistory: [],
      minTemp: 22,
      maxTemp: 35,
      minHumidity: 40,
      maxHumidity: 75,
      notes: 'Tumbuh subur, sudah mulai berbunga.',
    ),
    PlantModel(
      id: 'p004',
      name: 'Kangkung Pot C',
      type: 'Kangkung',
      emoji: '🌿',
      method: GrowingMethod.container,
      plantedDate: DateTime.now().subtract(const Duration(days: 18)),
      location: 'Balkon Lantai 2',
      status: PlantStatus.healthy,
      nextWatering: DateTime.now().add(const Duration(hours: 2)),
      careHistory: [
        'Penyiraman pagi - hari ini',
        'Pupuk cair organik - 4 hari lalu',
      ],
      diseaseHistory: [],
      minTemp: 20,
      maxTemp: 38,
      minHumidity: 50,
      maxHumidity: 85,
      notes: 'Tumbuh cepat, siap panen dalam 2 minggu.',
    ),
    PlantModel(
      id: 'p005',
      name: 'Basil Kemangi D',
      type: 'Kemangi',
      emoji: '🌱',
      method: GrowingMethod.soil,
      plantedDate: DateTime.now().subtract(const Duration(days: 25)),
      location: 'Windowsill Kamar',
      status: PlantStatus.needsAttention,
      nextWatering: DateTime.now().add(const Duration(minutes: 30)),
      lastDiagnosis: 'Kekurangan Air (Wilting)',
      careHistory: [
        'Pemangkasan pucuk - 8 hari lalu',
      ],
      diseaseHistory: [],
      minTemp: 18,
      maxTemp: 30,
      minHumidity: 45,
      maxHumidity: 70,
      notes: 'Perlu penyiraman lebih sering saat musim panas.',
    ),
    PlantModel(
      id: 'p006',
      name: 'Bayam Merah E',
      type: 'Bayam',
      emoji: '🍃',
      method: GrowingMethod.soil,
      plantedDate: DateTime.now().subtract(const Duration(days: 12)),
      location: 'Teras Belakang',
      status: PlantStatus.healthy,
      nextWatering: DateTime.now().add(const Duration(hours: 6)),
      careHistory: [
        'Semai benih - 12 hari lalu',
        'Penyiraman rutin - kemarin',
      ],
      diseaseHistory: [],
      minTemp: 18,
      maxTemp: 35,
      minHumidity: 50,
      maxHumidity: 80,
      notes: 'Masih fase seedling, pertumbuhan normal.',
    ),
  ];

  // ─── Alerts ───────────────────────────────────────────────────────────────

  static final List<AlertModel> alerts = [
    AlertModel(
      id: 'a001',
      type: AlertType.heatStress,
      severity: AlertSeverity.high,
      title: 'Heat Stress - Selada Hidroponik',
      description:
          'Suhu hari ini mencapai 34°C, melewati batas aman 28°C. Selada Hidroponik A berisiko mengalami tipburn dan layu.',
      plantName: 'Selada Hidroponik A',
      plantEmoji: '🥬',
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      actionRequired: 'Pindahkan ke tempat teduh atau naikkan shade netting. Pastikan sirkulasi air cukup.',
    ),
    AlertModel(
      id: 'a002',
      type: AlertType.fungusRisk,
      severity: AlertSeverity.critical,
      title: 'Risiko Jamur Tinggi - Tomat Cherry',
      description:
          'Kelembapan 3 hari ke depan >80% berpotensi memicu kambuhnya Early Blight pada Tomat Cherry A yang sedang karantina.',
      plantName: 'Tomat Cherry A',
      plantEmoji: '🍅',
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      actionRequired: 'Tingkatkan ventilasi, kurangi penyiraman daun, aplikasikan fungisida preventif.',
    ),
    AlertModel(
      id: 'a003',
      type: AlertType.uvHigh,
      severity: AlertSeverity.medium,
      title: 'UV Index Sangat Tinggi',
      description:
          'UV Index mencapai 8.2 (Sangat Tinggi) antara pukul 10:00–14:00. Tanaman di teras rentan terbakar.',
      plantName: 'Semua tanaman di teras',
      plantEmoji: '🌶️',
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      actionRequired: 'Pasang paranet/shade cloth selama jam puncak UV atau pindahkan sementara.',
    ),
    AlertModel(
      id: 'a004',
      type: AlertType.drought,
      severity: AlertSeverity.medium,
      title: 'Jadwal Siram Terlewat',
      description:
          'Basil Kemangi D belum disiram lebih dari 12 jam. Terdeteksi gejala wilting ringan.',
      plantName: 'Basil Kemangi D',
      plantEmoji: '🌱',
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      actionRequired: 'Siram segera dengan air secukupnya hingga tanah lembap merata.',
    ),
    AlertModel(
      id: 'a005',
      type: AlertType.heavyRain,
      severity: AlertSeverity.low,
      title: 'Hujan Lebat Diprediksi',
      description:
          'Curah hujan 22mm diprediksi 2 hari ke depan. Tanaman di pot outdoor perlu dilindungi dari genangan.',
      plantName: 'Semua tanaman outdoor',
      plantEmoji: '🪴',
      status: AlertStatus.handled,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      actionRequired: 'Pastikan drainase pot baik dan pindahkan tanaman sensitif ke dalam ruangan.',
    ),
  ];

  // ─── Diagnoses ────────────────────────────────────────────────────────────

  static final List<DiagnosisModel> diagnoses = [
    DiagnosisModel(
      id: 'd001',
      plantId: 'p002',
      plantName: 'Tomat Cherry A',
      plantEmoji: '🍅',
      diseaseName: 'Hawar Daun Awal',
      diseaseNameEn: 'Early Blight (Alternaria solani)',
      severity: DiseaseSeverity.moderate,
      diagnosisStatus: DiagnosisStatus.active,
      confidence: 0.94,
      description:
          'Early Blight adalah penyakit jamur yang disebabkan oleh Alternaria solani. Ditandai dengan bercak coklat konsentris pada daun tua, dikelilingi halo kuning. Menyebar cepat dalam kondisi lembap dan hangat.',
      solutions: [
        'Pangkas dan buang semua daun yang terinfeksi segera',
        'Semprotkan fungisida tembaga (copper-based) setiap 7-10 hari',
        'Hindari menyiram daun - siram hanya pangkal batang',
        'Tambahkan mulsa untuk mencegah spora tanah menyiprat ke daun',
        'Tingkatkan sirkulasi udara dengan mengurangi kepadatan tanaman',
      ],
      preventionTips: [
        'Rotasi tanaman setiap musim',
        'Gunakan varietas tahan penyakit',
        'Hindari overhead irrigation',
        'Bersihkan sisa tanaman setelah panen',
      ],
      diagnosedAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DiagnosisModel(
      id: 'd002',
      plantId: 'p005',
      plantName: 'Basil Kemangi D',
      plantEmoji: '🌱',
      diseaseName: 'Kekurangan Air (Layu)',
      diseaseNameEn: 'Water Stress / Wilting',
      severity: DiseaseSeverity.mild,
      diagnosisStatus: DiagnosisStatus.recovering,
      confidence: 0.89,
      description:
          'Tanaman menunjukkan gejala kekurangan air: daun terkulai, warna menguning di tepi, dan batang kurang tegak. Kondisi ini bisa memburuk di suhu tinggi.',
      solutions: [
        'Siram segera dengan air secukupnya',
        'Pastikan pot memiliki drainase yang baik',
        'Tempatkan di lokasi yang tidak terkena sinar matahari langsung saat siang',
        'Cek kelembapan tanah setiap pagi sebelum menyiram',
      ],
      preventionTips: [
        'Buat jadwal penyiraman rutin',
        'Gunakan pot dengan media tanam yang baik daya simpan airnya',
        'Pasang rempeyek/mulsa untuk menjaga kelembapan',
      ],
      diagnosedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    DiagnosisModel(
      id: 'd003',
      plantId: 'p001',
      plantName: 'Selada Hidroponik A',
      plantEmoji: '🥬',
      diseaseName: 'Tipburn (Kekurangan Kalsium)',
      diseaseNameEn: 'Tipburn - Calcium Deficiency',
      severity: DiseaseSeverity.mild,
      diagnosisStatus: DiagnosisStatus.resolved,
      confidence: 0.91,
      description:
          'Tipburn ditandai dengan tepi daun muda yang menjadi coklat dan mengering. Disebabkan oleh kurangnya kalsium atau sirkulasi udara rendah yang menghambat transpirasi daun.',
      solutions: [
        'Tambahkan kalsium ke larutan nutrisi (CaCl2)',
        'Tingkatkan sirkulasi udara di sekitar tanaman',
        'Kurangi konsentrasi nutrisi sementara',
        'Panen daun yang terinfeksi tipburn',
      ],
      preventionTips: [
        'Jaga EC larutan di 1.2–2.0 mS/cm',
        'Pastikan ventilasi baik',
        'Cek pH secara rutin (6.0–7.0)',
      ],
      diagnosedAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // ─── Articles ─────────────────────────────────────────────────────────────

  static final List<ArticleModel> articles = [
    ArticleModel(
      id: 'art001',
      title: 'Bertani Hidroponik di Apartemen: Panduan Lengkap',
      subtitle: 'Mulai dari pemilihan sistem hingga panen pertama',
      content: '',
      category: ArticleCategory.tutorial,
      emoji: '💧',
      readTime: '8 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      isFeatured: true,
    ),
    ArticleModel(
      id: 'art002',
      title: 'Cara Menghadapi Gelombang Panas: Lindungi Tanamanmu',
      subtitle: 'Strategi bertahan saat suhu Jakarta tembus 35°C',
      content: '',
      category: ArticleCategory.weather,
      emoji: '🌡️',
      readTime: '5 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      isFeatured: true,
    ),
    ArticleModel(
      id: 'art003',
      title: 'Mengenal Early Blight dan Cara Mengatasinya',
      subtitle: 'Penyakit paling umum pada tomat dan paprika',
      content: '',
      category: ArticleCategory.pest,
      emoji: '🍄',
      readTime: '6 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ArticleModel(
      id: 'art004',
      title: '10 Tanaman Herbal Terbaik untuk Urban Farming',
      subtitle: 'Mudah ditanam, bergizi tinggi, dan hemat ruang',
      content: '',
      category: ArticleCategory.plant,
      emoji: '🌿',
      readTime: '4 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ArticleModel(
      id: 'art005',
      title: 'pH dan EC: Kunci Sukses Hidroponik',
      subtitle: 'Pahami dua parameter paling krusial untuk hasil optimal',
      content: '',
      category: ArticleCategory.tips,
      emoji: '🧪',
      readTime: '7 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ArticleModel(
      id: 'art006',
      title: 'Manfaat Bertani Kota untuk Kesehatan Mental',
      subtitle: 'Penelitian terbaru: urban farming kurangi stres hingga 40%',
      content: '',
      category: ArticleCategory.tips,
      emoji: '🧠',
      readTime: '3 menit',
      publishedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  // ─── Helper getters ───────────────────────────────────────────────────────

  static int get healthyCount =>
      plants.where((p) => p.status == PlantStatus.healthy).length;

  static int get needsAttentionCount =>
      plants.where((p) => p.status == PlantStatus.needsAttention).length;

  static int get quarantineCount =>
      plants.where((p) => p.status == PlantStatus.quarantine).length;

  static List<AlertModel> get activeAlerts =>
      alerts.where((a) => a.status == AlertStatus.active).toList();

  static List<PlantModel> get urgentPlants => plants
      .where((p) =>
          p.status != PlantStatus.healthy ||
          p.isWateringDue)
      .toList();
}
