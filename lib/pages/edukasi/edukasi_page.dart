import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/article_model.dart';
import '../../models/plant_model.dart';
import '../../models/plant_type_model.dart';
import '../../models/weather_model.dart';
import '../../pages/kebunku/add_edit_plant_page.dart';
import '../../services/article_service.dart';
import '../../services/plant_firestore_service.dart';
import '../../services/plant_type_service.dart';
import '../../services/tip_generator_service.dart';
import '../../widgets/common/section_title.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({super.key});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _articlesKey = GlobalKey<_ArticlesTabState>();

  List<PlantTypeModel> _plantTypes = [];
  bool _plantTypesLoading = true;

  WeatherModel? _weather;
  List<ForecastDayModel> _forecast = [];
  List<PlantModel> _plants = [];
  bool _weatherError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadPlantTypes();
    _loadWeather();
    _loadPlants();
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
    if (mounted) setState(() => _weatherError = false);
    try {
      // Pakai cache dulu kalau sudah ada dari home page
      final cached = WeatherService.memCache;
      if (cached != null) {
        if (mounted) {
          setState(() {
            _weather = cached.current;
            _forecast = cached.forecast;
          });
        }
        return;
      }
      // Kalau belum ada cache, tunggu sebentar biar home selesai fetch
      await Future.delayed(const Duration(seconds: 3));
      final cachedAfterWait = WeatherService.memCache;
      if (cachedAfterWait != null) {
        if (mounted) {
          setState(() {
            _weather = cachedAfterWait.current;
            _forecast = cachedAfterWait.forecast;
          });
        }
        return;
      }
      // Kalau masih tidak ada, fetch sendiri
      final result = await WeatherService().fetchWeather();
      if (mounted) {
        setState(() {
          _weather = result.current;
          _forecast = result.forecast;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _weatherError = true);
    }
  }

  Future<void> _loadPlants() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;
      final plants = await PlantFirestoreService().watchPlants().first;
      if (mounted) setState(() => _plants = plants);
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
            _ArticlesTab(
              key: _articlesKey,
              weather: _weather,
              forecast: _forecast,
              plants: _plants,
            ),
            _plantTypesLoading
                ? const Center(child: CircularProgressIndicator())
                : _RecommendedPlantsTab(
                    plantTypes: _plantTypes,
                    weather: _weather,
                    forecast: _forecast,
                    weatherError: _weatherError,
                    onRetryWeather: _loadWeather,
                  ),
            _plantTypesLoading
                ? const Center(child: CircularProgressIndicator())
                : _CalendarTab(plantTypes: _plantTypes, forecast: _forecast),
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
        if (_tabController.index == 0)
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () => _articlesKey.currentState?.activateSearch(),
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
  final WeatherModel? weather;
  final List<ForecastDayModel> forecast;
  final List<PlantModel> plants;

  const _ArticlesTab({
    super.key,
    this.weather,
    this.forecast = const [],
    this.plants = const [],
  });

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  final _service = ArticleService();
  late Future<List<ArticleModel>> _future;
  ArticleCategory? _selectedCategory;
  String _searchQuery = '';
  bool _searchActive = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  List<ArticleModel> _surfaceContextual(
      List<ArticleModel> all, WeatherModel weather) {
    final result = <ArticleModel>[];
    final month = DateTime.now().month;

    // Suhu panas → artikel cuaca panas
    if (weather.temperature >= 32) {
      result.addAll(all.where((a) =>
          a.category == ArticleCategory.weather &&
          (a.title.toLowerCase().contains('panas') ||
              a.title.toLowerCase().contains('kemarau') ||
              a.title.toLowerCase().contains('uv'))));
    }

    // Kelembapan tinggi / hujan → artikel jamur & musim hujan
    if (weather.humidity >= 80 || weather.rainProbability >= 60) {
      result.addAll(all.where((a) =>
          a.category == ArticleCategory.weather &&
          (a.title.toLowerCase().contains('hujan') ||
              a.title.toLowerCase().contains('jamur') ||
              a.title.toLowerCase().contains('kelembapan')) ||
          a.category == ArticleCategory.pest &&
              (a.title.toLowerCase().contains('jamur') ||
                  a.title.toLowerCase().contains('bercak'))));
    }

    // Musim kemarau → artikel hemat air
    if ([6, 7, 8, 9].contains(month)) {
      result.addAll(all.where((a) =>
          a.title.toLowerCase().contains('kemarau') ||
          a.title.toLowerCase().contains('air')));
    }

    // Musim hujan → artikel musim hujan
    if ([11, 12, 1, 2].contains(month)) {
      result.addAll(all.where((a) =>
          a.title.toLowerCase().contains('hujan') ||
          a.category == ArticleCategory.pest));
    }

    // Deduplicate, max 3 artikel
    final seen = <String>{};
    return result.where((a) => seen.add(a.id)).take(3).toList();
  }

  void activateSearch() {
    setState(() => _searchActive = true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArticleModel> _applyFilters(List<ArticleModel> all) {
    var result = _selectedCategory == null
        ? all
        : all.where((a) => a.category == _selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.subtitle.toLowerCase().contains(q) ||
              a.content.toLowerCase().contains(q))
          .toList();
    }
    return result;
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
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);
        final isSearching = _searchQuery.isNotEmpty;
        final featured =
            isSearching ? <ArticleModel>[] : filtered.where((a) => a.isFeatured).toList();
        final others =
            isSearching ? filtered : filtered.where((a) => !a.isFeatured).toList();

        // Contextual surfacing: articles matching today's conditions
        final weather = widget.weather;
        final contextualArticles = isSearching || weather == null
            ? <ArticleModel>[]
            : _surfaceContextual(all, weather);

        // Tips hari ini
        final tips = weather == null
            ? <DailyTip>[]
            : TipGeneratorService.generate(
                weather: weather,
                forecast: widget.forecast,
                plants: widget.plants,
              );

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_searchActive) ...[
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari artikel...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textHint),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textHint),
                    onPressed: () => setState(() {
                      _searchActive = false;
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 16),
            ],
            if (!isSearching) ...[
              _CategoryChips(
                selected: _selectedCategory,
                onSelect: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 20),
              // ── Tips Hari Ini ──
              if (tips.isNotEmpty) ...[
                const SectionTitle(title: 'Tips Hari Ini'),
                const SizedBox(height: 12),
                _TipsCarousel(tips: tips),
                const SizedBox(height: 24),
              ],
              // ── Relevan untuk kondisi sekarang ──
              if (contextualArticles.isNotEmpty &&
                  _selectedCategory == null) ...[
                const SectionTitle(title: 'Relevan untuk Kondisi Hari Ini'),
                const SizedBox(height: 12),
                ...contextualArticles.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ArticleListCard(article: a, isHighlighted: true),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
            if (featured.isNotEmpty) ...[
              const SectionTitle(title: 'Artikel Pilihan'),
              const SizedBox(height: 12),
              _FeaturedArticleCard(article: featured.first),
              const SizedBox(height: 24),
            ],
            if (others.isNotEmpty) ...[
              SectionTitle(
                  title: isSearching
                      ? 'Hasil Pencarian (${others.length})'
                      : 'Semua Artikel'),
              const SizedBox(height: 12),
              ...others.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ArticleListCard(article: a),
                ),
              ),
            ],
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    isSearching
                        ? 'Tidak ada artikel yang cocok dengan "$_searchQuery".'
                        : 'Tidak ada artikel dalam kategori ini.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
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

// ── Tips Carousel ─────────────────────────────────────────────────────────────

class _TipsCarousel extends StatelessWidget {
  final List<DailyTip> tips;
  const _TipsCarousel({required this.tips});

  Color _bgColor(TipPriority p) {
    switch (p) {
      case TipPriority.urgent:
        return const Color(0xFFFFF3CD);
      case TipPriority.normal:
        return AppColors.accentDeep;
      case TipPriority.info:
        return AppColors.surfaceVariant;
    }
  }

  Color _borderColor(TipPriority p) {
    switch (p) {
      case TipPriority.urgent:
        return const Color(0xFFFFCC00);
      case TipPriority.normal:
        return AppColors.primaryLight;
      case TipPriority.info:
        return const Color(0xFFDDE8E0);
    }
  }

  Color _titleColor(TipPriority p) {
    switch (p) {
      case TipPriority.urgent:
        return const Color(0xFF7B5800);
      case TipPriority.normal:
        return AppColors.primaryDark;
      case TipPriority.info:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final tip = tips[i];
          return Container(
            width: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgColor(tip.priority),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor(tip.priority)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tip.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _titleColor(tip.priority),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tip.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: _titleColor(tip.priority).withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  final ArticleModel article;
  final bool isHighlighted;
  const _ArticleListCard(
      {required this.article, this.isHighlighted = false});

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
          color: isHighlighted ? AppColors.accentDeep : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primaryLight
                : const Color(0xFFE8F0EA),
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.surface
                    : AppColors.surfaceVariant,
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

enum _MatchLevel { both, weatherOnly, monthOnly }

class _RecommendedPlantsTab extends StatelessWidget {
  final List<PlantTypeModel> plantTypes;
  final WeatherModel? weather;
  final List<ForecastDayModel> forecast;
  final bool weatherError;
  final VoidCallback? onRetryWeather;

  const _RecommendedPlantsTab({
    required this.plantTypes,
    required this.forecast,
    this.weather,
    this.weatherError = false,
    this.onRetryWeather,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;

    bool matchesWeather(PlantTypeModel p) => weather != null &&
        weather!.temperature >= p.minTemp &&
        weather!.temperature <= p.maxTemp &&
        weather!.humidity >= p.minHumidity &&
        weather!.humidity <= p.maxHumidity;

    bool matchesMonth(PlantTypeModel p) => p.bestMonths.contains(currentMonth);

    _MatchLevel? level(PlantTypeModel p) {
      final w = matchesWeather(p);
      final m = matchesMonth(p);
      if (w && m) return _MatchLevel.both;
      if (w) return _MatchLevel.weatherOnly;
      if (m) return _MatchLevel.monthOnly;
      return null;
    }

    final withLevel = plantTypes
        .map((p) => (plant: p, level: level(p)))
        .where((e) => e.level != null)
        .toList()
      ..sort((a, b) => a.level!.index.compareTo(b.level!.index));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (weather != null)
          _WeatherContextCard(weather: weather!, forecast: forecast)
        else if (weatherError)
          GestureDetector(
            onTap: onRetryWeather,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('📍', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Gagal mengambil data cuaca. Izin lokasi mungkin belum diberikan.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Coba lagi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Cocok Ditanam Bulan Ini'),
        const SizedBox(height: 12),
        if (withLevel.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                weatherError
                    ? 'Rekomendasi membutuhkan data cuaca.'
                    : weather == null
                        ? 'Memuat data cuaca...'
                        : 'Tidak ada tanaman yang sesuai kondisi saat ini.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...withLevel.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendedPlantCard(plant: e.plant, matchLevel: e.level!),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _WeatherContextCard extends StatelessWidget {
  final WeatherModel weather;
  final List<ForecastDayModel> forecast;
  const _WeatherContextCard({required this.weather, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final avgMaxTemp = forecast.isEmpty
        ? weather.temperature
        : forecast.map((f) => f.maxTemp).reduce((a, b) => a + b) /
            forecast.length;
    final avgRain = forecast.isEmpty
        ? weather.rainProbability
        : forecast.map((f) => f.rainProbability).reduce((a, b) => a + b) /
            forecast.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Text(
                'Kondisi Minggu Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ForecastPill(
                  emoji: '🌡️',
                  label: 'Rata-rata maks',
                  value: '${avgMaxTemp.toStringAsFixed(0)}°C'),
              const SizedBox(width: 8),
              _ForecastPill(
                  emoji: '💧',
                  label: 'Peluang hujan',
                  value: '${avgRain.toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _ForecastPill(
                  emoji: '💦',
                  label: 'Kelembapan',
                  value: '${weather.humidity.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastPill extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _ForecastPill(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE8E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RecommendedPlantCard extends StatelessWidget {
  final PlantTypeModel plant;
  final _MatchLevel matchLevel;
  const _RecommendedPlantCard(
      {required this.plant, required this.matchLevel});

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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: matchLevel == _MatchLevel.both
                                ? AppColors.primary
                                : AppColors.accentDeep,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            matchLevel == _MatchLevel.both
                                ? '⭐ Cocok cuaca & bulan'
                                : matchLevel == _MatchLevel.weatherOnly
                                    ? '🌡️ Cocok cuaca'
                                    : '📅 Cocok bulan ini',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: matchLevel == _MatchLevel.both
                                  ? Colors.white
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
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
  final List<ForecastDayModel> forecast;
  const _CalendarTab({required this.plantTypes, required this.forecast});

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

    final isCurrentMonth = _selectedMonth == DateTime.now().month;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _MonthPicker(
          selectedMonth: _selectedMonth,
          onSelect: (m) => setState(() => _selectedMonth = m),
          months: _months,
        ),
        const SizedBox(height: 20),
        if (isCurrentMonth && widget.forecast.isNotEmpty) ...[
          _CalendarForecastCard(forecast: widget.forecast),
          const SizedBox(height: 20),
        ],
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

class _CalendarForecastCard extends StatelessWidget {
  final List<ForecastDayModel> forecast;
  const _CalendarForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌤️ Prakiraan 5 Hari ke Depan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: forecast.map((f) {
              final isRainy = f.rainProbability >= 60;
              return Expanded(
                child: Column(
                  children: [
                    Text(f.dayLabel,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textHint)),
                    const SizedBox(height: 4),
                    Text(f.conditionEmoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      '${f.maxTemp.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    if (isRainy)
                      Text(
                        '${f.rainProbability.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.info),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final avgRain =
                forecast.map((f) => f.rainProbability).reduce((a, b) => a + b) /
                    forecast.length;
            final avgMax =
                forecast.map((f) => f.maxTemp).reduce((a, b) => a + b) /
                    forecast.length;
            String hint;
            if (avgRain >= 60) {
              hint =
                  'Peluang hujan tinggi minggu ini. Kurangi penyiraman manual dan pastikan drainase lancar.';
            } else if (avgMax >= 33) {
              hint =
                  'Suhu cukup panas minggu ini. Siram pagi hari dan pertimbangkan shade net untuk tanaman sensitif.';
            } else {
              hint =
                  'Cuaca relatif ideal minggu ini. Waktu yang bagus untuk menanam atau memindahkan bibit.';
            }
            return Text(hint,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5));
          }),
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
