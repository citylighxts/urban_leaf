import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';

class ArticleService {
  static const _collection = 'articles';
  final _db = FirebaseFirestore.instance;

  Future<List<ArticleModel>> fetchAll() async {
    final snap = await _db
        .collection(_collection)
        .orderBy('publishedAt', descending: true)
        .get();
    return snap.docs.map((d) => ArticleModel.fromMap(d.data())).toList();
  }

  /// Seeds the collection only if it is empty.
  Future<void> seedIfEmpty() async {
    final snap = await _db.collection(_collection).limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final article in _seedData) {
      final ref = _db.collection(_collection).doc(article.id);
      batch.set(ref, article.toMap());
    }
    await batch.commit();
  }

  // Seed articles with educational content for Indonesian urban farmers.
  // publishedAt is stored as a fixed epoch so re-seeding produces stable ordering.
  static final List<ArticleModel> _seedData = [
    ArticleModel(
      id: 'art001',
      title: 'Bertani Hidroponik di Apartemen: Panduan Lengkap',
      subtitle: 'Mulai dari pemilihan sistem hingga panen pertama',
      content:
          'Hidroponik memungkinkan bercocok tanam tanpa tanah menggunakan larutan nutrisi. '
          'Sistem NFT (Nutrient Film Technique) paling cocok untuk pemula karena hemat air dan mudah dikontrol. '
          'Kunci sukses adalah menjaga pH larutan 5.5-6.5 dan EC 1.5-2.5 mS/cm.\n\n'
          'Pilih lokasi dengan minimal 6 jam cahaya matahari langsung, atau tambahkan LED grow light 16 jam per hari. '
          'Selada, pakcoy, dan bayam adalah tanaman terbaik untuk permulaan karena siklus panen 30-45 hari.\n\n'
          'Nutrisi AB Mix adalah solusi standar yang mengandung makronutrien (N, P, K, Ca, Mg, S) dan mikronutrien lengkap. '
          'Ganti larutan setiap 1-2 minggu dan bersihkan instalasi setiap siklus panen untuk mencegah penumpukan alga.',
      category: ArticleCategory.tutorial,
      emoji: '💧',
      readTime: '8 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748736000000),
      isFeatured: true,
    ),
    ArticleModel(
      id: 'art002',
      title: 'Cara Menghadapi Gelombang Panas: Lindungi Tanamanmu',
      subtitle: 'Strategi bertahan saat suhu Jakarta tembus 35°C',
      content:
          'Suhu di atas 35°C menyebabkan heat stress pada tanaman, ditandai layu di siang hari dan tipburn pada daun muda. '
          'Pasang shade cloth 30-50% untuk mengurangi intensitas cahaya dan suhu kanopi hingga 5-8°C.\n\n'
          'Siram pagi sebelum pukul 08.00 atau sore setelah pukul 16.00 untuk menghindari evaporasi berlebih. '
          'Tambahkan mulsa organik 5-10 cm di permukaan tanah untuk menjaga kelembapan dan menurunkan suhu akar.\n\n'
          'Tanaman paling rentan heat stress: selada, bayam, pakcoy, dan brokoli. '
          'Pindahkan sementara ke lokasi lebih teduh, atau gunakan teknik "misting" di sekitar kanopi setiap 2-3 jam pada jam puncak panas.',
      category: ArticleCategory.weather,
      emoji: '🌡️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748649600000),
      isFeatured: true,
    ),
    ArticleModel(
      id: 'art003',
      title: 'Mengenal Early Blight dan Cara Mengatasinya',
      subtitle: 'Penyakit paling umum pada tomat dan paprika',
      content:
          'Early Blight disebabkan oleh jamur Alternaria solani. Gejalanya adalah bercak coklat konsentris pada daun tua '
          'yang dikelilingi halo kuning. Spora menyebar melalui air hujan, percikan irigasi, dan kontak langsung.\n\n'
          'Langkah penanganan: (1) Pangkas dan musnahkan semua daun terinfeksi. (2) Semprotkan fungisida berbahan tembaga '
          '(copper hydroxide) setiap 7-10 hari. (3) Siram hanya di pangkal batang, hindari membasahi daun.\n\n'
          'Pencegahan jangka panjang: rotasi tanaman setiap musim, gunakan mulsa untuk mencegah spora tanah menyiprat, '
          'dan jaga jarak tanam 40-50 cm untuk sirkulasi udara yang baik.',
      category: ArticleCategory.pest,
      emoji: '🍄',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748563200000),
    ),
    ArticleModel(
      id: 'art004',
      title: '10 Tanaman Herbal Terbaik untuk Urban Farming',
      subtitle: 'Mudah ditanam, bergizi tinggi, dan hemat ruang',
      content:
          'Tanaman herbal adalah pilihan sempurna untuk urban farming karena hemat ruang, bernilai ekonomi tinggi, '
          'dan bisa dipanen berulang kali. Kemangi tumbuh sangat baik di iklim tropis dan berfungsi ganda sebagai '
          'penolak serangga alami.\n\n'
          'Daftar 5 herbal teratas untuk pemula: (1) Kemangi — aroma kuat, tumbuh cepat. (2) Mint peppermint — '
          'cocok di pot kecil, menyebar via stolon. (3) Rosemary — tahan kering, aromatik. '
          '(4) Daun bawang — panen berulang hanya dengan memotong. (5) Seledri — butuh kelembapan tinggi.\n\n'
          'Semua herbal ini bisa ditanam di pot ukuran 15-20 cm dan ditempatkan di windowsill dengan 4-6 jam cahaya matahari.',
      category: ArticleCategory.plant,
      emoji: '🌿',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748390400000),
    ),
    ArticleModel(
      id: 'art005',
      title: 'pH dan EC: Kunci Sukses Hidroponik',
      subtitle: 'Pahami dua parameter paling krusial untuk hasil optimal',
      content:
          'pH mengukur keasaman larutan nutrisi. Kisaran ideal 5.5-6.5 memungkinkan tanaman menyerap semua unsur hara. '
          'pH terlalu tinggi (>7) menyebabkan defisiensi besi dan mangan. pH terlalu rendah (<5) meracuni akar.\n\n'
          'EC (Electrical Conductivity) mengukur konsentrasi nutrisi dalam larutan. Panduan EC per fase:\n'
          '• Bibit/seedling: 0.8-1.2 mS/cm\n'
          '• Pertumbuhan vegetatif: 1.2-2.0 mS/cm\n'
          '• Pembungaan/pembuahan: 2.0-3.5 mS/cm\n\n'
          'Ukur pH dan EC setiap hari menggunakan pen meter digital. Koreksi pH dengan pH Up (KOH) atau '
          'pH Down (asam fosfat). Jangan koreksi lebih dari 0.5 unit per hari untuk menghindari shock pada tanaman.',
      category: ArticleCategory.tips,
      emoji: '🧪',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748217600000),
    ),
    ArticleModel(
      id: 'art006',
      title: 'Manfaat Bertani Kota untuk Kesehatan Mental',
      subtitle: 'Penelitian terbaru: urban farming kurangi stres hingga 40%',
      content:
          'Penelitian dari University of Essex (2013) menemukan berkebun selama 30 menit dapat menurunkan kadar '
          'kortisol (hormon stres) sebesar 20-40%. Interaksi dengan tanah mengekspos tubuh pada bakteri Mycobacterium vaccae '
          'yang merangsang produksi serotonin secara alami.\n\n'
          'Urban farming memberikan manfaat ganda: produktivitas nyata (pangan sendiri) sekaligus terapi mindfulness. '
          'Siklus menanam-merawat-memanen menciptakan struktur rutinitas yang terbukti membantu penderita kecemasan.\n\n'
          'Mulai dengan satu pot tanaman mudah seperti kemangi atau bayam. '
          'Luangkan 10-15 menit per hari untuk merawatnya, dan catat perkembangannya. '
          'Banyak petani kota melaporkan perasaan "accomplishment" yang signifikan saat panen pertama.',
      category: ArticleCategory.tips,
      emoji: '🧠',
      readTime: '3 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748044800000),
    ),
  ];
}
