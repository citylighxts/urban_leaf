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

  /// Force re-seed - overwrites all existing articles. Use when seed data is updated.
  Future<void> reseed() async {
    final batch = _db.batch();
    for (final article in _seedData) {
      final ref = _db.collection(_collection).doc(article.id);
      batch.set(ref, article.toMap());
    }
    await batch.commit();
  }

  static final List<ArticleModel> _seedData = [
    // ─── TUTORIAL ─────────────────────────────────────────────────────────────

    ArticleModel(
      id: 'art001',
      title: 'Bertani Hidroponik di Apartemen: Panduan Lengkap',
      subtitle: 'Mulai dari pemilihan sistem hingga panen pertama',
      content:
          'Hidroponik memungkinkan bercocok tanam tanpa tanah menggunakan larutan nutrisi. '
          'Sistem NFT (Nutrient Film Technique) paling cocok untuk pemula karena hemat air dan mudah dikontrol. '
          'Kunci sukses adalah menjaga pH larutan 5.5–6.5 dan EC 1.5–2.5 mS/cm.\n\n'
          'Pilih lokasi dengan minimal 6 jam cahaya matahari langsung, atau tambahkan LED grow light 16 jam per hari. '
          'Selada, pakcoy, dan bayam adalah tanaman terbaik untuk permulaan karena siklus panen 30–45 hari.\n\n'
          'Nutrisi AB Mix adalah solusi standar yang mengandung makronutrien (N, P, K, Ca, Mg, S) dan mikronutrien lengkap. '
          'Ganti larutan setiap 1–2 minggu dan bersihkan instalasi setiap siklus panen untuk mencegah penumpukan alga.',
      category: ArticleCategory.tutorial,
      emoji: '💧',
      readTime: '8 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748736000000),
      isFeatured: true,
    ),

    ArticleModel(
      id: 'art002',
      title: 'Sistem DWC: Cara Menanam Tomat di Ember',
      subtitle: 'Deep Water Culture - metode hidroponik paling sederhana',
      content:
          'Deep Water Culture (DWC) menggantungkan akar tanaman langsung dalam larutan nutrisi beroksigen. '
          'Yang dibutuhkan hanya ember gelap 10–20 liter, net pot, air pump aquarium, dan media tanam (rockwool/hydroton).\n\n'
          'Langkah setup: (1) Lubangi tutup ember seukuran net pot. (2) Isi ember 80% dengan larutan nutrisi pH 5.8–6.2. '
          '(3) Pasang air stone di dasar ember dan hubungkan ke pompa. (4) Tempatkan bibit di net pot dengan akar menyentuh larutan.\n\n'
          'Tomat, cabai, dan paprika tumbuh sangat baik di DWC karena akar mendapat oksigen dan nutrisi sekaligus. '
          'Pantau level air setiap hari - biarkan turun 2–3 cm sebelum diisi ulang agar zona udara terbentuk di atas larutan.',
      category: ArticleCategory.tutorial,
      emoji: '🪣',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748649600000),
    ),

    ArticleModel(
      id: 'art003',
      title: 'Menanam di Media Tanah: Campuran yang Ideal',
      subtitle: 'Komposisi tanah pot untuk sayuran dan herbal di perkotaan',
      content:
          'Media tanam pot yang baik harus ringan, porous, dan kaya nutrisi. Campuran ideal untuk sayuran: '
          '40% tanah kebun, 30% kompos matang, 20% sekam bakar, 10% perlite atau pasir kasar.\n\n'
          'Hindari tanah liat murni - terlalu berat dan mudah tergenang air sehingga menyebabkan busuk akar. '
          'Ciri media yang sehat: ketika digenggam menggumpal tapi langsung remah saat dilepas.\n\n'
          'Ganti media setiap 2–3 siklus tanam karena nutrisi terkuras dan struktur memburuk. '
          'Tambahkan pupuk slow-release NPK 15-15-15 saat menanam untuk suplai nutrisi 3 bulan pertama. '
          'Cacing tanah dalam pot adalah tanda media yang sangat sehat.',
      category: ArticleCategory.tutorial,
      emoji: '🪴',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748563200000),
    ),

    ArticleModel(
      id: 'art004',
      title: 'Vertical Garden: Memaksimalkan Tembok dan Pagar',
      subtitle: 'Solusi berkebun untuk lahan kurang dari 1 meter persegi',
      content:
          'Vertical garden adalah solusi terbaik untuk urban farming dengan lahan sangat terbatas. '
          'Sistem paling mudah: rak PVC berdiameter 4 inci dipotong 30 cm, dilubangi, dan disusun vertikal di dinding.\n\n'
          'Tanaman yang paling cocok untuk vertical garden: selada, pakcoy, stroberi, kemangi, dan seledri. '
          'Hindari tanaman dengan akar dalam seperti wortel atau umbi-umbian.\n\n'
          'Sistem irigasi tetes otomatis sangat direkomendasikan - pasang timer untuk menyiram 2x sehari '
          'selama 5–10 menit. Pastikan ada penampung air di bawah untuk recycle run-off dan mencegah kotor.\n\n'
          'Satu panel 1m x 2m bisa menampung 20–30 tanaman dan menghasilkan sayuran segar setiap minggu.',
      category: ArticleCategory.tutorial,
      emoji: '🧱',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748476800000),
    ),

    ArticleModel(
      id: 'art005',
      title: 'pH dan EC: Dua Parameter Krusial Hidroponik',
      subtitle: 'Pahami dan kendalikan keduanya untuk hasil maksimal',
      content:
          'pH mengukur keasaman larutan nutrisi. Kisaran ideal 5.5–6.5 memungkinkan tanaman menyerap semua unsur hara. '
          'pH terlalu tinggi (>7) menyebabkan defisiensi besi dan mangan - daun menguning. '
          'pH terlalu rendah (<5) meracuni akar dan menghambat penyerapan kalsium.\n\n'
          'EC (Electrical Conductivity) mengukur konsentrasi nutrisi. Panduan EC per fase:\n'
          '• Bibit/seedling: 0.8–1.2 mS/cm\n'
          '• Pertumbuhan vegetatif: 1.2–2.0 mS/cm\n'
          '• Pembungaan/pembuahan: 2.0–3.5 mS/cm\n\n'
          'Ukur pH dan EC setiap hari menggunakan pen meter digital. Koreksi pH dengan pH Up (KOH) atau '
          'pH Down (asam fosfat). Jangan koreksi lebih dari 0.5 unit per hari untuk menghindari shock.',
      category: ArticleCategory.tips,
      emoji: '🧪',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748390400000),
      isFeatured: true,
    ),

    ArticleModel(
      id: 'art006',
      title: 'Pencahayaan Buatan: Panduan Grow Light untuk Pemula',
      subtitle: 'LED, T5, atau HPS - mana yang tepat untuk kebunmu?',
      content:
          'Tanaman membutuhkan cahaya untuk fotosintesis. Jika cahaya matahari kurang dari 4 jam, grow light wajib dipasang.\n\n'
          'LED Full Spectrum adalah pilihan terbaik untuk pemula: konsumsi listrik rendah (20–50W cukup untuk 0.5 m²), '
          'tidak panas, umur panjang (50.000 jam). Pilih spektrum 3000K–4000K untuk pertumbuhan vegetatif, '
          '2700K untuk pembungaan.\n\n'
          'Atur jarak lampu ke puncak tanaman: LED 20–40 cm, T5 fluorescent 5–15 cm. '
          'Durasi pencahayaan: sayuran daun 14–16 jam/hari, buah-buahan 12 jam/hari. '
          'Gunakan timer otomatis untuk konsistensi - tanaman butuh periode gelap untuk proses metabolisme.',
      category: ArticleCategory.tutorial,
      emoji: '💡',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748304000000),
    ),

    ArticleModel(
      id: 'art007',
      title: 'Kompos dari Sampah Dapur: Panduan Lengkap',
      subtitle: 'Ubah sisa sayur dan buah menjadi pupuk premium',
      content:
          'Kompos adalah pupuk organik terbaik yang bisa dibuat sendiri dari sampah dapur. '
          'Bahan yang cocok: sisa sayuran, kulit buah, ampas kopi, cangkang telur, dan potongan tanaman.\n\n'
          'Hindari: daging, ikan, produk susu, dan minyak goreng - menarik hama dan berbau.\n\n'
          'Rasio ideal: 3 bagian "coklat" (daun kering, kardus, kertas) : 1 bagian "hijau" (sisa dapur). '
          'Aduk setiap 3–5 hari dan jaga kelembapan seperti spons basah. '
          'Komposter berputar (tumbler) mempercepat proses menjadi 4–6 minggu dibanding metode tumpukan biasa 3–6 bulan.\n\n'
          'Kompos matang berwarna gelap, berbau tanah, dan tidak terlihat bahan aslinya.',
      category: ArticleCategory.tutorial,
      emoji: '♻️',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748217600000),
    ),

    // ─── TANAMAN SPESIFIK ──────────────────────────────────────────────────────

    ArticleModel(
      id: 'art008',
      title: 'Panduan Lengkap Menanam Selada Hidroponik',
      subtitle: 'Dari semai hingga panen dalam 30–35 hari',
      content:
          'Selada adalah tanaman paling ideal untuk memulai hidroponik urban. Siklus cepat, tidak butuh banyak ruang, '
          'dan bisa dipanen berkali-kali dengan teknik cut-and-come-again.\n\n'
          'Varietas terbaik untuk panas Jakarta: Butterhead dan Oakleaf lebih toleran panas dibanding Romaine. '
          'Semai benih di rockwool cube yang sudah dibasahi, simpan di tempat teduh 5–7 hari hingga tumbuh 2 daun sejati.\n\n'
          'Kondisi optimal: suhu 20–28°C, pH 5.8–6.2, EC 1.0–1.8. Di atas 30°C selada cenderung bolting (berbunga '
          'dan rasa menjadi pahit). Panen ketika daun terluar mencapai 15–20 cm - potong 2 cm di atas pangkal '
          'untuk regenerasi.',
      category: ArticleCategory.plant,
      emoji: '🥬',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748131200000),
    ),

    ArticleModel(
      id: 'art009',
      title: 'Cara Berhasil Menanam Tomat di Pot',
      subtitle: 'Varietas, media, dan teknik penyangga untuk hasil maksimal',
      content:
          'Tomat bisa menghasilkan panen berlimpah di pot berukuran minimal 20 liter. '
          'Pilih varietas determinate (tomat semak) seperti Tomat Cherry atau Tomat Beef - lebih kompak dan tidak memanjang terus.\n\n'
          'Tomat butuh minimal 8 jam sinar matahari langsung. Pasang ajir (bambu/besi) sejak awal sebagai penyangga. '
          'Pangkas tunas air (sucker) yang tumbuh di ketiak daun secara rutin untuk memfokuskan energi ke buah.\n\n'
          'Pupuk: fase vegetatif gunakan NPK tinggi N (20-10-10). Begitu muncul bunga, ganti ke pupuk tinggi K (10-10-20) '
          'untuk mendorong pembentukan dan pematangan buah. Penyiraman konsisten kunci mencegah blossom end rot.',
      category: ArticleCategory.plant,
      emoji: '🍅',
      readTime: '8 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1748044800000),
    ),

    ArticleModel(
      id: 'art010',
      title: 'Menanam Cabai: Dari Semai Hingga Panen Berlimpah',
      subtitle: 'Rahasia cabai produktif sepanjang tahun di iklim tropis',
      content:
          'Cabai adalah tanaman yang sangat rewarding untuk urban farming - satu pohon bisa menghasilkan ratusan buah selama bertahun-tahun. '
          'Varietas yang direkomendasikan: Cabai Rawit Merah dan Cabai Keriting karena adaptif di dataran rendah panas.\n\n'
          'Semai di pot kecil dulu selama 4–6 minggu sebelum pindah ke pot besar (min. 5 liter). '
          'Cabai sangat sensitif terhadap genangan - pastikan media porous dan pot punya lubang drainase yang cukup.\n\n'
          'Pemupukan: setiap 2 minggu ganti antara pupuk N tinggi (fase tumbuh) dan K tinggi (fase berbuah). '
          'Semprotkan air ke bunga menggunakan tangan untuk membantu penyerbukan jika tidak ada angin. '
          'Panen rutin mendorong produksi buah baru - jangan biarkan buah terlalu lama di pohon.',
      category: ArticleCategory.plant,
      emoji: '🌶️',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747958400000),
    ),

    ArticleModel(
      id: 'art011',
      title: 'Kangkung: Tanaman Paling Mudah untuk Pemula',
      subtitle: 'Panen pertama dalam 3 minggu, bisa ditanam di air biasa',
      content:
          'Kangkung adalah tanaman paling toleran dan produktif untuk urban farming pemula. '
          'Tumbuh di mana saja - di tanah, pot, bahkan di ember berisi air tanpa sistem hidroponik apapun.\n\n'
          'Cara termudah: isi ember atau baskom dengan air, masukkan batang kangkung yang sudah punya akar (beli di pasar), '
          'taruh di bawah sinar matahari. Ganti air setiap 3–4 hari. Dalam 2–3 minggu sudah bisa dipanen.\n\n'
          'Untuk hasil lebih baik, tambahkan sedikit pupuk cair NPK ke air (1/4 dosis anjuran). '
          'Panen dengan memotong 10–15 cm dari ujung batang - sisakan 2–3 ruas daun agar tumbuh kembali. '
          'Satu rumpun kangkung bisa dipanen 8–10 kali sebelum perlu disemai ulang.',
      category: ArticleCategory.plant,
      emoji: '🌿',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747872000000),
    ),

    ArticleModel(
      id: 'art012',
      title: 'Kemangi: Herbal Serbaguna yang Wajib Ada di Dapur',
      subtitle: 'Menanam kemangi di pot kecil untuk panen harian',
      content:
          'Kemangi tumbuh sangat baik di iklim tropis Indonesia dan bisa dipanen setiap hari begitu dewasa. '
          'Tanam dari benih atau stek batang - stek lebih cepat, cukup rendam batang 5 cm dalam air 1 minggu hingga berakar.\n\n'
          'Kemangi butuh 4–6 jam sinar matahari dan media yang tidak terlalu basah. '
          'Pot 15–20 cm sudah cukup untuk 2–3 tanaman. Petik pucuk secara rutin untuk mencegah berbunga - '
          'begitu kemangi berbunga, daun mengecil dan rasa berkurang.\n\n'
          'Manfaat ganda: aroma kemangi mengusir kutu daun dan nyamuk secara alami. '
          'Tanam di sekitar tomat atau cabai untuk perlindungan organik.',
      category: ArticleCategory.plant,
      emoji: '🌱',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747785600000),
    ),

    ArticleModel(
      id: 'art013',
      title: 'Pakcoy dan Bayam: Duo Sayuran Tercepat untuk Panen',
      subtitle: 'Siap konsumsi dalam 25–30 hari dari semai',
      content:
          'Pakcoy dan bayam adalah pilihan sempurna untuk urban farmer yang ingin hasil cepat. '
          'Keduanya bisa ditanam bersamaan - sebar benih langsung di media, tidak perlu semai terpisah.\n\n'
          'Pakcoy lebih toleran panas dibanding bayam, cocok untuk dataran rendah seperti Jakarta dan Surabaya. '
          'Bayam Merah lebih tahan panas dibanding Bayam Hijau, dan nilai gizinya lebih tinggi (kaya antosianin).\n\n'
          'Jarak tanam: 15x15 cm untuk pakcoy, 10x10 cm untuk bayam. Siram 2x sehari pagi dan sore. '
          'Panen bisa dilakukan sekaligus (cabut seluruh tanaman) atau bertahap (petik daun luar saja). '
          'Rotasi tanam setiap bulan untuk suplai sayuran yang tidak terputus.',
      category: ArticleCategory.plant,
      emoji: '🥦',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747699200000),
    ),

    ArticleModel(
      id: 'art014',
      title: 'Stroberi di Pot: Buah Manis dari Balkon Rumah',
      subtitle: 'Varietas dan teknik khusus untuk iklim panas Indonesia',
      content:
          'Stroberi menantang di Indonesia karena butuh suhu sejuk, namun varietas modern sudah adaptif di dataran rendah. '
          'Pilih varietas Day Neutral seperti Albion atau Seascape yang tidak bergantung panjang hari.\n\n'
          'Media tanam: campuran tanah + kompos + sekam bakar dengan pH 5.5–6.5. '
          'Pot strawberry (bertingkat dengan lubang samping) ideal karena menghemat ruang.\n\n'
          'Stroberi butuh 6–8 jam sinar matahari dan penyiraman konsisten - tanah tidak boleh kering total maupun tergenang. '
          'Buang runner (sulur panjang) jika tidak ingin memperbanyak tanaman, agar energi fokus ke buah. '
          'Pupuk tinggi Kalium dan Fosfor setelah muncul bunga untuk buah yang lebih manis.',
      category: ArticleCategory.plant,
      emoji: '🍓',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747612800000),
    ),

    ArticleModel(
      id: 'art015',
      title: '10 Tanaman Herbal Terbaik untuk Urban Farming',
      subtitle: 'Mudah ditanam, bergizi tinggi, dan hemat ruang',
      content:
          'Tanaman herbal adalah pilihan sempurna untuk urban farming karena hemat ruang, bernilai ekonomi tinggi, '
          'dan bisa dipanen berulang kali. Kemangi tumbuh sangat baik di iklim tropis dan berfungsi ganda sebagai '
          'penolak serangga alami.\n\n'
          'Top 5 herbal untuk pemula: (1) Kemangi - aroma kuat, tumbuh cepat. (2) Mint peppermint - '
          'cocok di pot kecil, menyebar via stolon. (3) Rosemary - tahan kering, aromatik. '
          '(4) Daun bawang - panen berulang hanya dengan memotong. (5) Seledri - butuh kelembapan tinggi.\n\n'
          'Semua herbal ini bisa ditanam di pot ukuran 15–20 cm dan ditempatkan di windowsill dengan 4–6 jam cahaya.',
      category: ArticleCategory.plant,
      emoji: '🌿',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747526400000),
    ),

    ArticleModel(
      id: 'art016',
      title: 'Wortel Mini di Pot: Bisa, Asal Tahu Caranya',
      subtitle: 'Pilih varietas pendek dan media yang tepat',
      content:
          'Wortel bisa ditanam di pot asal memilih varietas pendek (chantenay atau danvers) dengan kedalaman akar 15–20 cm. '
          'Pot atau polybag minimal 30 cm dalamnya.\n\n'
          'Media wajib: tanah pasiran atau campuran pasir kasar 40% + kompos 40% + tanah 20%. '
          'Media yang terlalu padat membuat wortel bercabang atau bengkok.\n\n'
          'Sebar benih langsung (tidak bisa distek atau dicangkok). Jarak antar benih 3 cm, tipis-tipis. '
          'Setelah berkecambah dan tinggi 5 cm, jarangkan hingga jarak 5–7 cm antar tanaman. '
          'Siram hati-hati - jangan sampai benih terbawa air. Panen ketika pangkal terlihat melebar di permukaan tanah (60–75 hari).',
      category: ArticleCategory.plant,
      emoji: '🥕',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747440000000),
    ),

    // ─── HAMA & PENYAKIT ──────────────────────────────────────────────────────

    ArticleModel(
      id: 'art017',
      title: 'Mengenal dan Mengatasi Early Blight pada Tomat',
      subtitle: 'Penyakit jamur paling umum yang menyerang tomat dan cabai',
      content:
          'Early Blight disebabkan oleh jamur Alternaria solani. Gejalanya: bercak coklat konsentris pada daun tua '
          'yang dikelilingi halo kuning. Spora menyebar melalui air hujan, percikan irigasi, dan kontak langsung.\n\n'
          'Penanganan: (1) Pangkas dan musnahkan semua daun terinfeksi. (2) Semprotkan fungisida berbahan tembaga '
          '(copper hydroxide) setiap 7–10 hari. (3) Siram hanya di pangkal batang, hindari membasahi daun.\n\n'
          'Pencegahan: rotasi tanaman setiap musim, mulsa untuk mencegah spora tanah menyiprat, '
          'jaga jarak tanam 40–50 cm untuk sirkulasi udara yang baik.',
      category: ArticleCategory.pest,
      emoji: '🍄',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747353600000),
    ),

    ArticleModel(
      id: 'art018',
      title: 'Kutu Daun: Identifikasi dan Pembasmi Alami',
      subtitle: 'Kendalikan aphid tanpa pestisida kimia berbahaya',
      content:
          'Kutu daun (aphid) adalah hama paling umum pada urban farming. Ukurannya sangat kecil (1–3 mm) dan biasanya '
          'berwarna hijau, kuning, atau hitam, bergerombol di bawah daun dan pucuk muda.\n\n'
          'Kerusakan: mengisap cairan tanaman, menyebabkan daun keriting dan menguning. Juga menyebarkan virus tanaman.\n\n'
          'Pembasmi alami yang efektif:\n'
          '• Semprotkan air kencang untuk menghempaskan koloni dari daun\n'
          '• Larutan sabun cuci piring encer (1 sendok teh per 1 liter air) disemprotkan ke seluruh permukaan daun\n'
          '• Larutan bawang putih: blender 5 siung bawang putih + 1 liter air, diamkan semalam, saring, semprotkan\n'
          '• Tanam kemangi atau mint di sekitar tanaman sebagai penolak alami\n\n'
          'Semprotkan sore hari - hindari siang hari agar tanaman tidak terbakar.',
      category: ArticleCategory.pest,
      emoji: '🐛',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747267200000),
    ),

    ArticleModel(
      id: 'art019',
      title: 'Penyakit Busuk Akar: Penyebab dan Pencegahan',
      subtitle: 'Pythium dan Fusarium - pembunuh senyap di sistem hidroponik',
      content:
          'Busuk akar (root rot) adalah ancaman terbesar di sistem hidroponik, disebabkan jamur Pythium atau Fusarium. '
          'Tanda awal: akar berwarna coklat atau hitam (normal putih bersih), berbau busuk, tanaman layu meski nutrisi cukup.\n\n'
          'Penyebab utama: suhu larutan terlalu tinggi (>25°C), kurang oksigen di akar, larutan jarang diganti.\n\n'
          'Penanganan: (1) Cabut tanaman, cuci akar dengan air bersih. (2) Rendam 30 menit dalam larutan H2O2 3% (1:4 dengan air). '
          '(3) Ganti seluruh larutan nutrisi. (4) Bersihkan wadah dengan larutan klorin encer.\n\n'
          'Pencegahan: jaga suhu larutan di bawah 22°C (tambahkan es batu saat cuaca panas), '
          'pastikan pompa udara bekerja 24 jam, ganti larutan setiap 10–14 hari.',
      category: ArticleCategory.pest,
      emoji: '🦠',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747180800000),
    ),

    ArticleModel(
      id: 'art020',
      title: 'Tungau Laba-Laba: Musuh Tersembunyi di Musim Kemarau',
      subtitle: 'Spider mite meledak populasinya saat udara panas dan kering',
      content:
          'Tungau laba-laba (spider mite) sangat kecil dan sulit dilihat mata telanjang, '
          'tapi kerusakannya cepat dan parah. Tanda infestasi: bintik putih/kuning kecil di permukaan atas daun, '
          'jaring halus di bawah daun, daun menguning dan rontok.\n\n'
          'Populasi meledak saat suhu >30°C dan kelembapan rendah (<40%). Musim kemarau adalah puncaknya.\n\n'
          'Pengendalian alami:\n'
          '• Tingkatkan kelembapan dengan menyemprot air ke sekitar tanaman (bukan ke daun)\n'
          '• Semprotkan larutan sulfur organik atau minyak neem encer (2 ml/liter air) ke seluruh permukaan daun\n'
          '• Predator alami: tungau predator Phytoseiulus persimilis bisa dibeli online\n\n'
          'Ulangi setiap 5 hari selama 3 siklus untuk memutus siklus hidup telur.',
      category: ArticleCategory.pest,
      emoji: '🕷️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747094400000),
    ),

    ArticleModel(
      id: 'art021',
      title: 'Penyakit Bercak Daun: Jamur yang Merajalela di Musim Hujan',
      subtitle: 'Kenali gejala dan obati sebelum menyebar ke seluruh kebun',
      content:
          'Penyakit bercak daun (leaf spot) disebabkan berbagai jamur dan bakteri yang berkembang pesat '
          'saat kelembapan tinggi dan sirkulasi udara buruk. Gejalanya beragam: bercak hitam, coklat, atau kuning '
          'dengan tepi yang jelas di permukaan daun.\n\n'
          'Kondisi yang memicu: daun terkena air hujan langsung, jarak tanam terlalu rapat, sirkulasi udara minim.\n\n'
          'Penanganan:\n'
          '• Pangkas daun terinfeksi dan buang jauh dari area tanam\n'
          '• Semprotkan fungisida berbasis tembaga atau mankozeb setiap 7 hari\n'
          '• Perbaiki sirkulasi udara dengan memangkas tanaman yang terlalu rimbun\n\n'
          'Di musim hujan, pertimbangkan atap plastik transparan di atas tanaman untuk mengurangi percikan air.',
      category: ArticleCategory.pest,
      emoji: '🌿',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1747008000000),
    ),

    ArticleModel(
      id: 'art022',
      title: 'Ulat Daun: Cara Organik Membasmi Tanpa Racun',
      subtitle: 'Bacillus thuringiensis - solusi biologis yang aman dan efektif',
      content:
          'Ulat daun (caterpillar) adalah larva dari berbagai ngengat yang memakan daun dengan cepat - '
          'satu ulat bisa menghabiskan satu daun dalam semalam. Ciri serangan: lubang tidak beraturan di daun, '
          'kotoran ulat (frass) berwarna hijau tua di permukaan daun.\n\n'
          'Solusi organik terbaik: Bacillus thuringiensis var. kurstaki (Bt-k) adalah bakteri alami '
          'yang hanya mematikan ulat, tidak berbahaya bagi manusia, hewan, atau serangga berguna. '
          'Tersedia dalam bentuk serbuk atau cair, semprotkan sore hari ke seluruh permukaan daun.\n\n'
          'Pencegahan fisik: pasang jaring halus (insect net) di atas tanaman untuk mencegah ngengat bertelur. '
          'Periksa bawah daun secara rutin - telur dan ulat kecil lebih mudah dibasmi.',
      category: ArticleCategory.pest,
      emoji: '🦋',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746921600000),
    ),

    // ─── CUACA & MUSIM ────────────────────────────────────────────────────────

    ArticleModel(
      id: 'art023',
      title: 'Cara Menghadapi Gelombang Panas: Lindungi Tanamanmu',
      subtitle: 'Strategi bertahan saat suhu tembus 35°C',
      content:
          'Suhu di atas 35°C menyebabkan heat stress pada tanaman, ditandai layu di siang hari dan tipburn pada daun muda. '
          'Pasang shade cloth 30–50% untuk mengurangi intensitas cahaya dan suhu kanopi hingga 5–8°C.\n\n'
          'Siram pagi sebelum pukul 08.00 atau sore setelah pukul 16.00 untuk menghindari evaporasi berlebih. '
          'Tambahkan mulsa organik 5–10 cm di permukaan tanah untuk menjaga kelembapan dan menurunkan suhu akar.\n\n'
          'Tanaman paling rentan heat stress: selada, bayam, pakcoy, dan brokoli. '
          'Pindahkan sementara ke lokasi lebih teduh, atau gunakan teknik misting di sekitar kanopi setiap 2–3 jam.',
      category: ArticleCategory.weather,
      emoji: '🌡️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746835200000),
      isFeatured: true,
    ),

    ArticleModel(
      id: 'art024',
      title: 'Berkebun di Musim Hujan: Peluang dan Tantangan',
      subtitle: 'Maksimalkan curah hujan, minimalkan risiko jamur',
      content:
          'Musim hujan membawa berkah (air melimpah, suhu lebih sejuk) sekaligus tantangan (kelembapan tinggi, '
          'risiko jamur, tanah tergenang). Dengan strategi tepat, musim hujan justru bisa menjadi musim terbaik berkebun.\n\n'
          'Yang harus dilakukan:\n'
          '• Perbaiki drainase - pastikan semua pot punya lubang pembuangan yang tidak tersumbat\n'
          '• Naikkan pot ke rak atau bangku agar tidak terendam saat hujan deras\n'
          '• Pasang atap plastik transparan sebagian untuk tanaman sensitif\n'
          '• Kurangi frekuensi penyiraman - tanah sudah mendapat air dari hujan\n\n'
          'Tanaman yang justru berkembang di musim hujan: kangkung, bayam, sawi, dan pakcoy. '
          'Hindari menanam tomat dan cabai saat hujan terus-menerus karena sangat rentan jamur.',
      category: ArticleCategory.weather,
      emoji: '🌧️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746748800000),
    ),

    ArticleModel(
      id: 'art025',
      title: 'Musim Kemarau: Strategi Hemat Air untuk Kebun Urban',
      subtitle: 'Irigasi tetes, mulsa, dan pemilihan tanaman yang tepat',
      content:
          'Musim kemarau (Juni–September) adalah ujian terbesar untuk urban farmer. '
          'Kunci bertahan: kurangi kehilangan air, tingkatkan efisiensi irigasi.\n\n'
          'Sistem irigasi tetes (drip irrigation) menghemat air hingga 70% dibanding siram manual. '
          'DIY sederhana: botol plastik dibolongi tutupnya dengan jarum, tancapkan terbalik ke tanah.\n\n'
          'Mulsa adalah investasi terbaik di musim kemarau: lapisan daun kering, jerami, atau serpihan kayu '
          '5–10 cm di atas tanah mengurangi evaporasi 50–70% dan menjaga suhu akar lebih rendah.\n\n'
          'Pilihan tanaman tahan kering: tomat, cabai, terong, labu, dan semua tanaman herbal mediterania '
          '(rosemary, thyme, sage). Tunda menanam selada dan bayam sampai musim hujan tiba.',
      category: ArticleCategory.weather,
      emoji: '☀️',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746662400000),
    ),

    ArticleModel(
      id: 'art026',
      title: 'UV Index Tinggi: Apa Artinya untuk Tanamanmu?',
      subtitle: 'Pahami indeks UV dan kapan harus memasang perlindungan',
      content:
          'UV Index mengukur intensitas radiasi ultraviolet matahari yang sampai ke permukaan bumi. '
          'Untuk tanaman, UV tinggi meningkatkan fotosintesis tapi juga mempercepat penguapan air.\n\n'
          'Panduan UV Index untuk berkebun:\n'
          '• UV 1–4 (Rendah–Sedang): aman untuk semua tanaman, termasuk yang sensitif\n'
          '• UV 5–7 (Tinggi): awasi tanaman berdaun tipis, siram lebih sering\n'
          '• UV 8–10 (Sangat Tinggi): pasang shade net untuk selada, bayam, dan herbal\n'
          '• UV 11+ (Ekstrem): pindahkan tanaman sensitif ke tempat teduh parsial\n\n'
          'Tanaman tropis asli (tomat, cabai, terong) lebih toleran UV tinggi. '
          'Bayam dan selada bisa terbakar daun (leaf scorch) jika UV di atas 8 tanpa naungan.',
      category: ArticleCategory.weather,
      emoji: '🌞',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746576000000),
    ),

    ArticleModel(
      id: 'art027',
      title: 'Angin Kencang dan Tanaman: Cara Melindungi Kebun Balkon',
      subtitle: 'Windbreak, penyangga, dan pilihan tanaman tahan angin',
      content:
          'Angin kencang di balkon apartemen tinggi bisa merusak tanaman secara fisik dan mempercepat penguapan air. '
          'Tanaman yang patah atau miring permanen kehilangan produktivitasnya.\n\n'
          'Strategi perlindungan:\n'
          '• Pasang windbreak dari kain shading, bambu, atau pot besar sebagai penyangga di sisi angin\n'
          '• Gunakan pot berbobot berat atau isi dasar dengan batu kerikil agar tidak terjatuh\n'
          '• Pasang ajir lebih awal untuk tomat, cabai, dan tanaman tinggi\n'
          '• Kelompokkan pot kecil di belakang pot besar sebagai pelindung\n\n'
          'Tanaman paling tahan angin: rosemary, kemangi, kangkung, dan bayam. '
          'Paling rentan: tomat muda, paprika, dan tanaman berdaun lebar.',
      category: ArticleCategory.weather,
      emoji: '🌬️',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746489600000),
    ),

    ArticleModel(
      id: 'art028',
      title: 'Kelembapan Tinggi dan Risiko Jamur: Panduan Pencegahan',
      subtitle: 'Apa yang harus dilakukan saat RH di atas 80%',
      content:
          'Kelembapan relatif (RH) di atas 80% adalah kondisi ideal bagi jamur patogen untuk berkembang. '
          'Di Indonesia, kondisi ini umum terjadi sepanjang musim hujan dan subuh-pagi hari.\n\n'
          'Tanda awal serangan jamur: lapisan putih seperti bedak di daun (powdery mildew), '
          'bercak abu-abu berbulu (botrytis), atau daun menguning dari bawah.\n\n'
          'Langkah pencegahan:\n'
          '• Sirkulasi udara - jangan merapatkan pot, beri jarak minimal 20 cm antar tanaman\n'
          '• Hindari menyiram daun - siram hanya di pangkal\n'
          '• Pangkas daun tua di bagian bawah yang tidak mendapat cahaya\n'
          '• Semprot larutan baking soda encer (1 sendok teh per 1 liter air) sebagai antijamur preventif\n\n'
          'Jika sudah terinfeksi, isolasi segera tanaman yang sakit dari yang sehat.',
      category: ArticleCategory.weather,
      emoji: '💦',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746403200000),
    ),

    // ─── TIPS UMUM ─────────────────────────────────────────────────────────────

    ArticleModel(
      id: 'art029',
      title: 'Manfaat Bertani Kota untuk Kesehatan Mental',
      subtitle: 'Riset membuktikan: berkebun 30 menit turunkan stres hingga 40%',
      content:
          'Penelitian dari University of Essex menemukan berkebun selama 30 menit dapat menurunkan kadar '
          'kortisol (hormon stres) sebesar 20–40%. Interaksi dengan tanah mengekspos tubuh pada bakteri Mycobacterium vaccae '
          'yang merangsang produksi serotonin secara alami.\n\n'
          'Urban farming memberikan manfaat ganda: produktivitas nyata (pangan sendiri) sekaligus terapi mindfulness. '
          'Siklus menanam-merawat-memanen menciptakan struktur rutinitas yang terbukti membantu penderita kecemasan.\n\n'
          'Mulai dengan satu pot tanaman mudah seperti kemangi atau bayam. '
          'Luangkan 10–15 menit per hari untuk merawatnya dan catat perkembangannya. '
          'Banyak petani kota melaporkan perasaan accomplishment yang signifikan saat panen pertama.',
      category: ArticleCategory.tips,
      emoji: '🧠',
      readTime: '3 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746316800000),
    ),

    ArticleModel(
      id: 'art030',
      title: 'Penyiraman yang Benar: Kapan, Berapa, dan Bagaimana',
      subtitle: 'Kesalahan penyiraman adalah penyebab kematian tanaman nomor satu',
      content:
          'Overwatering (terlalu banyak siram) lebih sering membunuh tanaman daripada kekeringan. '
          'Cara cek: masukkan jari 2–3 cm ke media tanah. Jika masih lembap, tunggu dulu.\n\n'
          'Waktu terbaik menyiram: pagi hari (06.00–08.00). Air sempat meresap sebelum panas siang, '
          'daun mengering sebelum malam (mencegah jamur). Hindari menyiram siang hari - air menguap sia-sia '
          'dan bisa membakar daun.\n\n'
          'Cara menyiram yang benar: siram perlahan di pangkal batang, bukan dari atas daun. '
          'Siram hingga air keluar dari lubang drainase bawah pot - tanda seluruh media basah merata. '
          'Biarkan 15–20% volume air keluar sebagai run-off untuk mencuci garam mineral berlebih.',
      category: ArticleCategory.tips,
      emoji: '🚿',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746230400000),
    ),

    ArticleModel(
      id: 'art031',
      title: 'Pupuk Organik vs Kimia: Mana yang Lebih Baik?',
      subtitle: 'Perbandingan jujur untuk urban farmer',
      content:
          'Pupuk kimia (anorganik) kerjanya cepat - nutrisi langsung tersedia bagi tanaman dalam hitungan jam. '
          'Cocok untuk tanaman yang butuh dorongan segera atau tanaman dalam pot. '
          'Risikonya: mudah overdosis, menumpuk garam di media, merusak biota tanah jangka panjang.\n\n'
          'Pupuk organik (kompos, pupuk kandang, guano) bekerja lebih lambat tapi membangun struktur media, '
          'meningkatkan populasi mikroba baik, dan tidak ada risiko overdosis.\n\n'
          'Rekomendasi: kombinasikan keduanya. Gunakan pupuk organik sebagai dasar media dan top dressing rutin. '
          'Tambahkan pupuk kimia slow-release (NPK coated) untuk suplai nutrisi konsisten. '
          'Simpan pupuk kimia cepat untuk situasi darurat saat tanaman butuh nutrisi mendesak.',
      category: ArticleCategory.tips,
      emoji: '⚗️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746144000000),
    ),

    ArticleModel(
      id: 'art032',
      title: 'Rotasi Tanaman: Kunci Produktivitas Kebun Jangka Panjang',
      subtitle: 'Jangan tanam tanaman yang sama di tempat yang sama terus-menerus',
      content:
          'Rotasi tanaman adalah praktik mengganti jenis tanaman di lokasi yang sama setiap siklus tanam. '
          'Di urban farming, ini berarti mengganti tanaman dalam satu pot atau area tertentu secara bergantian.\n\n'
          'Manfaat rotasi:\n'
          '• Mencegah penumpukan patogen spesifik di media\n'
          '• Mengurangi ketergantungan nutrisi yang sama (tiap tanaman punya kebutuhan nutrisi berbeda)\n'
          '• Memutus siklus hama yang sudah bertelur di media\n\n'
          'Pola rotasi sederhana: Sayuran daun → Tanaman berbuah → Kacang-kacangan → Istirahatkan/ganti media.\n\n'
          'Untuk pot: setelah 2–3 siklus tanam jenis yang sama, ganti media sepenuhnya atau biarkan pot kosong '
          '2 minggu di bawah terik matahari untuk sterilisasi alami.',
      category: ArticleCategory.tips,
      emoji: '🔄',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1746057600000),
    ),

    ArticleModel(
      id: 'art033',
      title: 'Urban Farming dengan Budget Minimal: Mulai dari Rp 50.000',
      subtitle: 'Panduan memulai kebun kota tanpa perlu investasi besar',
      content:
          'Banyak yang mengira urban farming butuh peralatan mahal. Faktanya, kamu bisa mulai dengan modal sangat kecil.\n\n'
          'Paket starter Rp 50.000:\n'
          '• Sachet benih bayam atau kangkung (Rp 5.000–10.000)\n'
          '• Tanah pot + sekam bakar dari toko tanaman (Rp 15.000)\n'
          '• Polybag ukuran 30x30 cm x 5 lembar (Rp 10.000)\n'
          '• Pupuk NPK 100 gram (Rp 10.000)\n\n'
          'Gunakan barang bekas sebagai pot: botol galon, ember cat bekas, kaleng biskuit - yang penting ada lubang drainase. '
          'Air bekas cucian beras mengandung mineral dan bisa menggantikan pupuk cair untuk tanaman sayuran.\n\n'
          'Setelah panen pertama, biasanya udah kecanduan dan upgrade sendiri secara bertahap.',
      category: ArticleCategory.tips,
      emoji: '💰',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745971200000),
    ),

    ArticleModel(
      id: 'art034',
      title: 'Semai Benih yang Benar: Panduan Langkah demi Langkah',
      subtitle: 'Tingkat keberhasilan semai bisa mencapai 90% dengan teknik ini',
      content:
          'Penyemaian yang benar menentukan kualitas tanaman sejak awal. Benih yang disemai di kondisi tidak ideal '
          'menghasilkan bibit lemah yang rawan penyakit sepanjang hidupnya.\n\n'
          'Langkah-langkah:\n'
          '1. Rendam benih keras (tomat, cabai) dalam air hangat 30°C selama 4–6 jam untuk mempercepat perkecambahan\n'
          '2. Gunakan media semai khusus (cocopeat/rockwool) yang steril dan porous\n'
          '3. Tanam benih sedalam 2x diameter benih\n'
          '4. Tutup dengan plastik wrap/sungkup untuk menjaga kelembapan\n'
          '5. Simpan di tempat hangat (25–28°C) tapi tidak langsung matahari\n'
          '6. Begitu berkecambah, buka sungkup dan pindah ke lokasi dengan cahaya cukup\n\n'
          'Pindah tanam (transplant) setelah muncul 3–4 daun sejati, bukan daun kotiledon.',
      category: ArticleCategory.tutorial,
      emoji: '🌱',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745884800000),
    ),

    ArticleModel(
      id: 'art035',
      title: 'Pemangkasan: Seni Membentuk Tanaman untuk Produksi Optimal',
      subtitle: 'Kapan, di mana, dan bagaimana memangkas dengan benar',
      content:
          'Pemangkasan bukan hanya estetika - ini manajemen energi tanaman. Dengan memangkas bagian tidak produktif, '
          'tanaman fokus menghasilkan buah atau daun yang lebih berkualitas.\n\n'
          'Tomat indeterminate: pangkas semua sucker (tunas ketiak) kecuali 1–2 batang utama. '
          'Hasilnya buah lebih besar meski jumlah lebih sedikit.\n\n'
          'Kemangi dan herbal: pangkas pucuk bunga segera saat muncul. Ini membuat tanaman terus berdaun lebat.\n\n'
          'Aturan pemangkasan:\n'
          '• Selalu gunakan gunting steril (celup alkohol dulu)\n'
          '• Pangkas di pagi hari agar luka mengering sebelum malam\n'
          '• Jangan pangkas lebih dari 30% massa tanaman sekaligus\n'
          '• Setelah memangkas tanaman sakit, sterilkan alat sebelum ke tanaman berikutnya',
      category: ArticleCategory.tips,
      emoji: '✂️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745798400000),
    ),

    ArticleModel(
      id: 'art036',
      title: 'Penyerbukan Manual: Bantu Tanamanmu Berbuah di Balkon',
      subtitle: 'Teknik mudah untuk tomat, cabai, dan paprika tanpa lebah',
      content:
          'Tomat, cabai, dan paprika butuh penyerbukan untuk berbuah. Di alam terbuka, angin dan lebah yang membantu. '
          'Di balkon tertutup atau ruangan dalam, kita perlu melakukannya manual.\n\n'
          'Cara termudah - ketuk ringan: ketuk batang atau tangkai bunga dengan jari atau pensil saat bunga sedang mekar penuh. '
          'Lakukan 2–3x sehari di siang hari (saat serbuk sari paling kering). Getaran memindahkan serbuk sari ke putik.\n\n'
          'Cara dengan kuas: gunakan kuas cat kecil yang lembut, putar-putar lembut di dalam setiap bunga '
          'untuk mengumpulkan dan memindahkan serbuk sari. Lebih efektif tapi butuh waktu lebih lama.\n\n'
          'Tanda berhasil: bunga yang terserbuki akan tetap mekar 1–2 hari lagi lalu kelopak gugur dan calon buah muncul.',
      category: ArticleCategory.tips,
      emoji: '🌸',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745712000000),
    ),

    ArticleModel(
      id: 'art037',
      title: 'Membaca Label Pupuk: Arti NPK dan Cara Memilih yang Tepat',
      subtitle: 'N, P, K - tiga angka yang menentukan nasib tanamanmu',
      content:
          'Setiap label pupuk punya tiga angka, misalnya 20-10-10 atau 10-15-20. '
          'Angka ini adalah persentase N (Nitrogen), P (Fosfor), dan K (Kalium).\n\n'
          'Fungsi masing-masing:\n'
          '• N (Nitrogen): mendorong pertumbuhan daun dan batang. Tinggi N untuk sayuran daun.\n'
          '• P (Fosfor): mendukung perkembangan akar dan pembungaan. Tinggi P untuk awal tanam dan fase bunga.\n'
          '• K (Kalium): memperkuat batang, meningkatkan kualitas buah, tahan penyakit. Tinggi K untuk fase buah.\n\n'
          'Panduan pemilihan:\n'
          '• Sayuran daun (selada, bayam, kangkung): pilih 30-10-10 atau sejenisnya\n'
          '• Tanaman berbuah fase vegetatif: 20-10-10\n'
          '• Tanaman berbuah fase generatif: 10-10-20 atau 6-30-30\n'
          '• Akar dan umbi: 5-20-20',
      category: ArticleCategory.tips,
      emoji: '🏷️',
      readTime: '5 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745625600000),
    ),

    ArticleModel(
      id: 'art038',
      title: 'Defisiensi Nutrisi: Baca Tanda SOS dari Tanamanmu',
      subtitle: 'Warna dan bentuk daun adalah petunjuk nutrisi yang kurang',
      content:
          'Daun adalah "display" kesehatan tanaman. Perubahan warna dan bentuk daun sering menunjukkan nutrisi yang kurang.\n\n'
          'Panduan visual:\n'
          '• Daun tua menguning merata → Nitrogen kurang (N)\n'
          '• Tepi daun tua kecoklatan/terbakar → Kalium kurang (K) atau kelebihan garam\n'
          '• Daun muda menguning, tulang daun tetap hijau → Defisiensi Besi (Fe) atau Mangan (Mn), biasanya pH terlalu tinggi\n'
          '• Daun ungu kemerahan → Fosfor kurang (P) atau suhu terlalu dingin\n'
          '• Titik coklat di tepi daun muda → Kalsium kurang (Ca) atau kelembapan tidak konsisten\n\n'
          'Sebelum menambah pupuk, cek dulu pH media - pH yang salah membuat nutrisi tidak bisa diserap '
          'meski tersedia dalam jumlah cukup.',
      category: ArticleCategory.tips,
      emoji: '🔍',
      readTime: '6 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745539200000),
    ),

    ArticleModel(
      id: 'art039',
      title: 'Aquaponik Mini: Ikan dan Sayuran Tumbuh Bersama',
      subtitle: 'Sistem sirkular yang tidak butuh pupuk kimia sama sekali',
      content:
          'Aquaponik menggabungkan budidaya ikan (akuakultur) dengan hidroponik dalam satu sistem tertutup. '
          'Kotoran ikan menjadi pupuk alami bagi tanaman, tanaman membersihkan air untuk ikan.\n\n'
          'Setup mini untuk pemula: akuarium 100–200 liter berisi ikan nila atau lele + rak tanaman di atasnya. '
          'Pompa mengalirkan air dari akuarium ke rak tanaman, air yang sudah disaring kembali ke akuarium.\n\n'
          'Tidak perlu pupuk kimia - kotoran ikan sudah menyediakan N, P, K yang dibutuhkan tanaman. '
          'Hemat air 90% dibanding pertanian konvensional karena air terus bersirkulasi.\n\n'
          'Tanaman terbaik untuk aquaponik: selada, pakcoy, bayam, kangkung, tomat cherry, dan herbal. '
          'Hasil ganda: panen ikan setiap 4–6 bulan, panen sayuran setiap 30–45 hari.',
      category: ArticleCategory.tutorial,
      emoji: '🐟',
      readTime: '7 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745452800000),
    ),

    ArticleModel(
      id: 'art040',
      title: 'Dokumentasi Kebun: Kenapa Catatan Tanam Itu Penting',
      subtitle: 'Kebun yang terdokumentasi menghasilkan 30% lebih produktif',
      content:
          'Petani berpengalaman selalu mencatat - tanggal tanam, varietas, dosis pupuk, masalah yang muncul, '
          'dan hasil panen. Tanpa catatan, kesalahan akan diulang terus.\n\n'
          'Yang wajib dicatat:\n'
          '• Tanggal semai dan pindah tanam\n'
          '• Jenis dan dosis pupuk yang dipakai\n'
          '• Hama atau penyakit yang muncul dan cara penanganannya\n'
          '• Tanggal dan jumlah hasil panen\n'
          '• Catatan cuaca saat terjadi kejadian penting\n\n'
          'Catatan ini membantu mengidentifikasi pola: varietas mana yang paling produktif di musimmu, '
          'pupuk apa yang paling efektif, kapan hama biasanya muncul. '
          'Dengan UrbanLeaf AI, semua catatan ini bisa tersimpan otomatis untuk setiap tanaman.',
      category: ArticleCategory.tips,
      emoji: '📓',
      readTime: '4 menit',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(1745366400000),
    ),
  ];
}
