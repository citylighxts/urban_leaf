import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/article_model.dart';
import '../../models/plant_type_model.dart';
import '../../models/weather_model.dart';
import '../../pages/kebunku/add_edit_plant_page.dart';
import '../../services/article_service.dart';
import '../../services/plant_type_service.dart';
import '../../widgets/common/section_title.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({super.key});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<PlantTypeModel> _plantTypes = [];
  bool _plantTypesLoading = true;

  WeatherModel? _weather;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlantTypes();
    _loadWeather();
  }

  Future<void> _loadPlantTypes() async {
    try {
      final types = await PlantTypeService().fetchAll();
      if (mounted) {
        setState(() {
          _plantTypes = types;
          _plantTypesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _plantTypesLoading = false);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final result = await WeatherService().fetchWeather();
      if (mounted) setState(() => _weather = result.current);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: [
            const _ArticlesTab(),
            _plantTypesLoading
                ? const Center(child: CircularProgressIndicator())
                : _RecommendedPlantsTab(plantTypes: _plantTypes, weather: _weather),
            _plantTypesLoading
                ? const Center(child: CircularProgressIndicator())
                : _CalendarTab(plantTypes: _plantTypes),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 20,
      toolbarHeight: 60,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edukasi 📚',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          Text('Panduan Urban Farming', style: AppTextStyles.caption),
        ],
      ),
      actions: [
        IconButton(
          icon:
              const Icon(Icons.search_rounded, color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Artikel'),
          Tab(text: 'Rekomendasi'),
          Tab(text: 'Kalender Tanam'),
        ],
      ),
    );
  }
}

// ─── Articles Tab ─────────────────────────────────────────────────────────────

class _ArticlesTab extends StatefulWidget {
  const _ArticlesTab();

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  final _service = ArticleService();
  late Future<List<ArticleModel>> _future;
  ArticleCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArticleModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('Gagal memuat artikel',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() => _future = _service.fetchAll()),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _selectedCategory == null
            ? all
            : all.where((a) => a.category == _selectedCategory).toList();
        final featured = filtered.where((a) => a.isFeatured).toList();
        final others = filtered.where((a) => !a.isFeatured).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CategoryChips(
              selected: _selectedCategory,
              onSelect: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 20),
            if (featured.isNotEmpty) ...[
              const SectionTitle(title: 'Artikel Pilihan'),
              const SizedBox(height: 12),
              _FeaturedArticleCard(article: featured.first),
              const SizedBox(height: 24),
            ],
            const SectionTitle(title: 'Semua Artikel'),
            const SizedBox(height: 12),
            ...others.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArticleListCard(article: a),
              ),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Tidak ada artikel dalam kategori ini.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final ArticleCategory? selected;
  final ValueChanged<ArticleCategory?> onSelect;

  const _CategoryChips({required this.selected, required this.onSelect});

  static const _categories = [
    (null, 'Semua', '📖'),
    (ArticleCategory.tips, 'Tips', '💡'),
    (ArticleCategory.tutorial, 'Tutorial', '🎓'),
    (ArticleCategory.weather, 'Cuaca', '🌤️'),
    (ArticleCategory.plant, 'Tanaman', '🌿'),
    (ArticleCategory.pest, 'Hama', '🐛'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final (type, label, emoji) = cat;
          final isSelected = selected == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE0ECE4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  final ArticleModel article;
  const _FeaturedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _ArticleDetailPage(article: article)),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Text(
                article.emoji,
                style: TextStyle(
                  fontSize: 100,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.categoryLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(article.readTime,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Baca →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  final ArticleModel article;
  const _ArticleListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _ArticleDetailPage(article: article)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F0EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child:
                    Text(article.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      article.categoryLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(article.readTime, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Recommended Plants Tab ───────────────────────────────────────────────────

class _RecommendedPlantsTab extends StatelessWidget {
  final List<PlantTypeModel> plantTypes;
  final WeatherModel? weather;
  const _RecommendedPlantsTab({required this.plantTypes, this.weather});

  @override
  Widget build(BuildContext context) {
    // Filter plant types whose tolerance range covers the current weather.
    final recommended = weather == null
        ? <PlantTypeModel>[]
        : plantTypes.where((p) =>
            weather!.temperature >= p.minTemp &&
            weather!.temperature <= p.maxTemp &&
            weather!.humidity >= p.minHumidity &&
            weather!.humidity <= p.maxHumidity).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (weather != null) _WeatherContextCard(weather: weather!),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Cocok Ditanam Bulan Ini'),
        const SizedBox(height: 12),
        if (recommended.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Tidak ada tanaman yang sesuai kondisi cuaca saat ini.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...recommended.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendedPlantCard(plant: p),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _WeatherContextCard extends StatelessWidget {
  final WeatherModel weather;
  const _WeatherContextCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekomendasi untuk Bulan Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suhu rata-rata ${weather.temperature.toStringAsFixed(0)}°C · Kelembapan ${weather.humidity.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPlantCard extends StatelessWidget {
  final PlantTypeModel plant;
  const _RecommendedPlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plant.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.name, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Kesulitan: ${plant.difficulty}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditPlantPage(
                      preselectedTypeId: plant.id,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tanam', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(plant.reason, style: AppTextStyles.bodySmall),
          if (plant.benefits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plant.benefits
                  .map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Calendar Tab ─────────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final List<PlantTypeModel> plantTypes;
  const _CalendarTab({required this.plantTypes});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  int _selectedMonth = DateTime.now().month;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final forMonth = widget.plantTypes
        .where((p) => p.bestMonths.contains(_selectedMonth))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MonthPicker(
          selectedMonth: _selectedMonth,
          onSelect: (m) => setState(() => _selectedMonth = m),
          months: _months,
        ),
        const SizedBox(height: 20),
        Text(
          'Cocok Ditanam di ${_months[_selectedMonth - 1]}',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        if (forMonth.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Tidak ada tanaman khusus untuk bulan ini.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          )
        else
          ...forMonth.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CalendarPlantTile(plant: p),
            ),
          ),
        const SizedBox(height: 20),
        _SeasonalTipsCard(month: _selectedMonth),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final int selectedMonth;
  final ValueChanged<int> onSelect;
  final List<String> months;

  const _MonthPicker({
    required this.selectedMonth,
    required this.onSelect,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (ctx, i) {
          final month = i + 1;
          final isSelected = selectedMonth == month;
          final isCurrent = DateTime.now().month == month;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(month),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent && !isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : isSelected
                            ? AppColors.primary
                            : const Color(0xFFE0ECE4),
                    width: isCurrent && !isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    months[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarPlantTile extends StatelessWidget {
  final PlantTypeModel plant;
  const _CalendarPlantTile({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Row(
        children: [
          Text(plant.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(plant.plantingTip, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.healthyLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Cocok ✓',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.healthy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalTipsCard extends StatelessWidget {
  final int month;
  const _SeasonalTipsCard({required this.month});

  String get _seasonalTip {
    if ([3, 4, 5].contains(month)) {
      return '🌧️ Musim Hujan: Waspadai pertumbuhan jamur akibat kelembapan tinggi. Perkuat drainase dan ventilasi tanaman.';
    } else if ([6, 7, 8, 9].contains(month)) {
      return '☀️ Musim Kemarau: Intensitas sinar tinggi dan curah hujan minim. Tingkatkan frekuensi penyiraman dan pasang shade net.';
    } else {
      return '🌤️ Musim Peralihan: Cuaca tidak menentu. Pantau perubahan suhu dan kelembapan lebih sering untuk respon cepat.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Tip Musiman',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _seasonalTip,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Article Detail ───────────────────────────────────────────────────────────

class _ArticleDetailPage extends StatelessWidget {
  final ArticleModel article;
  const _ArticleDetailPage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.weatherGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(article.emoji,
                        style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categoryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: AppTextStyles.headingLarge),
                  const SizedBox(height: 6),
                  Text(article.subtitle, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(article.readTime, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  if (article.content.isNotEmpty)
                    Text(
                      article.content,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
                    )
                  else
                    _ArticleBodyPlaceholder(article: article),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleBodyPlaceholder extends StatelessWidget {
  final ArticleModel article;
  const _ArticleBodyPlaceholder({required this.article});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mengapa Ini Penting?', style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),
        Text(
          '${article.subtitle}. Dengan memahami topik ini, kamu dapat meningkatkan produktivitas kebunmu dan menjaga tanaman tetap sehat sepanjang tahun.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Artikel lengkap akan tersedia setelah integrasi CMS selesai.',
                  style: TextStyle(fontSize: 13, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
