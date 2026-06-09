import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/diagnosis_model.dart';
import '../../models/plant_model.dart';
import '../../models/weather_model.dart';
import '../../services/diagnosis_firestore_service.dart';
import '../../services/plant_firestore_service.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/status_chip.dart';
import 'add_edit_plant_page.dart';

class PlantDetailPage extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailPage({super.key, required this.plant});

  @override
  State<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends State<PlantDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PlantModel _plant;
  final _plantService = PlantFirestoreService();
  final _diagnosisService = DiagnosisFirestoreService();

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _tabController = TabController(length: 3, vsync: this);
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
        headerSliverBuilder: (context, _) => [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildInfoCard()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(plant: _plant),
            _CareHistoryTab(plant: _plant),
            _DiagnosisStreamTab(
              stream: _diagnosisService.watchDiagnosesByPlant(_plant.id),
              diagnosisService: _diagnosisService,
              plant: _plant,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        plant: _plant,
        onWaterNow: () async {
          final messenger = ScaffoldMessenger.of(context);
          final now = DateTime.now();
          final updatedPlant = _plant.copyWith(
            status: _plant.status == PlantStatus.quarantine
                ? PlantStatus.quarantine
                : PlantStatus.healthy,
            nextWatering: now.add(const Duration(hours: 24)),
            lastWateredAt: now,
            careHistory: [
              'Disiram — ${_formatDateTime(now)}',
              ..._plant.careHistory,
            ],
          );

          final savedPlant = await _plantService.updatePlant(updatedPlant);

          if (!mounted) return;
          setState(() => _plant = savedPlant);
          messenger.showSnackBar(
            SnackBar(
              content: const Text('✅ Tanaman berhasil disiram!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        onEdit: () async {
          final navigator = Navigator.of(context);
          final result = await navigator.push<PlantModel>(
            MaterialPageRoute(builder: (_) => AddEditPlantPage(plant: _plant)),
          );
          if (result != null) setState(() => _plant = result);
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.weatherGradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(_plant.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                _plant.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _plant.type,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onPressed: () => _showMoreOptions(),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Row(
        children: [
          _QuickStat(
            value: '${_plant.ageInDays}',
            unit: 'hari',
            label: 'Usia',
            emoji: '📅',
          ),
          _Divider(),
          _QuickStat(
            value: _plant.isWateringDue ? 'Sekarang' : _nextWaterLabel,
            unit: '',
            label: 'Siram',
            emoji: '💧',
            highlight: _plant.isWateringDue,
          ),
          _Divider(),
          Column(
            children: [
              const Text('🌡️', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                '${_plant.minTemp.toStringAsFixed(0)}–${_plant.maxTemp.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text('Toleransi', style: AppTextStyles.caption),
            ],
          ),
          _Divider(),
          Column(
            children: [
              PlantStatusChip(status: _plant.status),
              const SizedBox(height: 4),
              const Text('Status', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String get _nextWaterLabel {
    final diff = _plant.nextWatering.difference(DateTime.now());
    if (diff.inHours < 1) return '< 1 jam';
    if (diff.inHours < 24) return '${diff.inHours}j lagi';
    return '${diff.inDays}h lagi';
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MoreOptionsSheet(
        plant: _plant,
        onToggleQuarantine: () async {
          final messenger = ScaffoldMessenger.of(context);
          final isQuarantined = _plant.status == PlantStatus.quarantine;
          final updatedPlant = isQuarantined
              ? _plant.copyWith(
                  status: _plant.previousStatus ?? PlantStatus.healthy,
                  previousStatus: null,
                )
              : _plant.copyWith(
                  previousStatus: _plant.status,
                  status: PlantStatus.quarantine,
                );

          final savedPlant = await _plantService.updatePlant(updatedPlant);
          if (!mounted) return;
          setState(() => _plant = savedPlant);
          Navigator.pop(ctx);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                isQuarantined
                    ? 'Tanaman berhasil keluar dari karantina'
                    : 'Tanaman ditandai karantina',
              ),
              backgroundColor: isQuarantined
                  ? AppColors.success
                  : AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        onShare: () async {
          final shareText = [
            'Tanaman: ${_plant.name}',
            'Jenis: ${_plant.type}',
            'Lokasi: ${_plant.location}',
            'Status: ${_plant.statusLabel}',
            'Penyiraman terakhir: ${_plant.lastWateredLabel}',
            'Kondisi terbaru: ${_plant.latestConditionLabel}',
          ].join('\n');

          await Share.share(shareText, subject: 'Bagikan Tanaman');
        },
        onDelete: () async {
          final navigator = Navigator.of(context);
          await _plantService.deletePlant(_plant.id);
          if (!mounted) return;
          navigator.pop();
          navigator.pop('deleted');
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _TabBarDelegate({required this.tabController});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Informasi'),
          Tab(text: 'Riwayat Perawatan'),
          Tab(text: 'Riwayat Penyakit'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _InfoTab extends StatelessWidget {
  final PlantModel plant;
  const _InfoTab({required this.plant});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Section(
          title: 'Detail Tanaman',
          children: [
            InfoRow(label: 'Nama', value: plant.name),
            InfoRow(label: 'Jenis', value: plant.type),
            InfoRow(label: 'Metode Tanam', value: plant.methodLabel),
            InfoRow(label: 'Lokasi', value: plant.location),
            InfoRow(
              label: 'Kondisi Terbaru',
              value: plant.latestConditionLabel,
            ),
            InfoRow(
              label: 'Penyiraman Terakhir',
              value: plant.lastWateredLabel,
            ),
            InfoRow(
              label: 'Tanggal Tanam',
              value:
                  '${plant.plantedDate.day}/${plant.plantedDate.month}/${plant.plantedDate.year}',
            ),
            InfoRow(label: 'Usia', value: '${plant.ageInDays} hari'),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Parameter Toleransi',
          children: [
            InfoRow(
              label: 'Suhu',
              value:
                  '${plant.minTemp.toStringAsFixed(0)}°C – ${plant.maxTemp.toStringAsFixed(0)}°C',
            ),
            InfoRow(
              label: 'Kelembapan',
              value:
                  '${plant.minHumidity.toStringAsFixed(0)}% – ${plant.maxHumidity.toStringAsFixed(0)}%',
            ),
          ],
        ),
        if (plant.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Catatan',
            children: [Text(plant.notes, style: AppTextStyles.bodyMedium)],
          ),
        ],
        const SizedBox(height: 16),
        _WeatherCompatibilityCard(plant: plant),
      ],
    );
  }
}

class _WeatherCompatibilityCard extends StatefulWidget {
  final PlantModel plant;
  const _WeatherCompatibilityCard({required this.plant});

  @override
  State<_WeatherCompatibilityCard> createState() =>
      _WeatherCompatibilityCardState();
}

class _WeatherCompatibilityCardState extends State<_WeatherCompatibilityCard> {
  WeatherModel? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await WeatherService().fetchWeather();
      if (mounted) setState(() { _weather = result.current; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kondisi Cuaca Saat Ini', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Gagal memuat cuaca', style: TextStyle(color: AppColors.danger, fontSize: 12))
          else ...[
            _CompatRow(
              label: 'Suhu ${_weather!.temperature.toStringAsFixed(0)}°C',
              isOk: _weather!.temperature >= widget.plant.minTemp &&
                  _weather!.temperature <= widget.plant.maxTemp,
              note: _weather!.temperature >= widget.plant.minTemp &&
                      _weather!.temperature <= widget.plant.maxTemp
                  ? 'Aman (toleransi ${widget.plant.minTemp.toStringAsFixed(0)}–${widget.plant.maxTemp.toStringAsFixed(0)}°C)'
                  : 'Melewati batas aman! Max ${widget.plant.maxTemp.toStringAsFixed(0)}°C',
            ),
            const SizedBox(height: 8),
            _CompatRow(
              label: 'Kelembapan ${_weather!.humidity.toStringAsFixed(0)}%',
              isOk: _weather!.humidity >= widget.plant.minHumidity &&
                  _weather!.humidity <= widget.plant.maxHumidity,
              note: _weather!.humidity >= widget.plant.minHumidity &&
                      _weather!.humidity <= widget.plant.maxHumidity
                  ? 'Aman (toleransi ${widget.plant.minHumidity.toStringAsFixed(0)}–${widget.plant.maxHumidity.toStringAsFixed(0)}%)'
                  : 'Di luar batas aman',
            ),
            const SizedBox(height: 8),
            Text(
              '${_weather!.conditionEmoji} ${_weather!.condition} · ${_weather!.location}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompatRow extends StatelessWidget {
  final String label;
  final bool isOk;
  final String note;

  const _CompatRow({
    required this.label,
    required this.isOk,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isOk ? AppColors.healthyLight : AppColors.dangerLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOk ? Icons.check_rounded : Icons.warning_rounded,
            size: 16,
            color: isOk ? AppColors.healthy : AppColors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
              ),
              Text(
                note,
                style: TextStyle(
                  fontSize: 11,
                  color: isOk ? AppColors.textSecondary : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CareHistoryTab extends StatelessWidget {
  final PlantModel plant;
  const _CareHistoryTab({required this.plant});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: plant.careHistory.isEmpty ? 1 : plant.careHistory.length,
      itemBuilder: (context, index) {
        if (plant.careHistory.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Belum ada riwayat perawatan'),
            ),
          );
        }
        final care = plant.careHistory[index];
        return _TimelineItem(
          label: care,
          isFirst: index == 0,
          isLast: index == plant.careHistory.length - 1,
          color: AppColors.primary,
          icon: Icons.eco_rounded,
        );
      },
    );
  }
}

class _DiagnosisStreamTab extends StatelessWidget {
  final Stream<List<DiagnosisModel>> stream;
  final DiagnosisFirestoreService diagnosisService;
  final PlantModel plant;

  const _DiagnosisStreamTab({
    required this.stream,
    required this.diagnosisService,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DiagnosisModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat riwayat penyakit',
                style: TextStyle(color: AppColors.danger)),
          );
        }
        return _DiagnosisTab(
          diagnoses: snapshot.data ?? [],
          plant: plant,
          diagnosisService: diagnosisService,
        );
      },
    );
  }
}

class _DiagnosisTab extends StatelessWidget {
  final List<DiagnosisModel> diagnoses;
  final PlantModel plant;
  final DiagnosisFirestoreService diagnosisService;

  const _DiagnosisTab({
    required this.diagnoses,
    required this.plant,
    required this.diagnosisService,
  });

  @override
  Widget build(BuildContext context) {
    if (diagnoses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Tidak ada riwayat penyakit',
              style: AppTextStyles.headingSmall,
            ),
            SizedBox(height: 4),
            Text('Tanaman kamu sehat!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: diagnoses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _DiagnosisCard(
        diagnosis: diagnoses[index],
        diagnosisService: diagnosisService,
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  final DiagnosisFirestoreService diagnosisService;

  const _DiagnosisCard({
    required this.diagnosis,
    required this.diagnosisService,
  });

  @override
  Widget build(BuildContext context) {
    final (severityColor, severityBg) = switch (diagnosis.severity) {
      DiseaseSeverity.mild => (AppColors.success, AppColors.successLight),
      DiseaseSeverity.moderate => (AppColors.warning, AppColors.warningLight),
      DiseaseSeverity.severe => (AppColors.danger, AppColors.dangerLight),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diagnosis.severityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diagnosis.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(diagnosis.confidence * 100).toStringAsFixed(0)}% akurat',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(diagnosis.diseaseName, style: AppTextStyles.headingSmall),
          const SizedBox(height: 2),
          Text(
            diagnosis.diseaseNameEn,
            style: AppTextStyles.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(diagnosis.description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 10),
          const Text('Solusi:', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          ...diagnosis.solutions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: AppTextStyles.bodySmall),
                  Expanded(child: Text(s, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Didiagnosis: ${_formatDate(diagnosis.diagnosedAt)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusDropdown(
                  current: diagnosis.diagnosisStatus,
                  onChanged: (status) => diagnosisService
                      .updateStatus(diagnosis.id, status)
                      .catchError((_) {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 20),
                tooltip: 'Hapus diagnosis',
                onPressed: () =>
                    diagnosisService.deleteDiagnosis(diagnosis.id).catchError((_) {}),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

extension _DiagnosisStatusLabel on DiagnosisStatus {
  String get statusLabel => switch (this) {
        DiagnosisStatus.active => 'Aktif',
        DiagnosisStatus.recovering => 'Membaik',
        DiagnosisStatus.resolved => 'Sembuh',
      };
}

class _StatusDropdown extends StatelessWidget {
  final DiagnosisStatus current;
  final ValueChanged<DiagnosisStatus> onChanged;

  const _StatusDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DiagnosisStatus>(
      initialValue: current,
      isDense: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
        ),
      ),
      items: DiagnosisStatus.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.statusLabel, style: AppTextStyles.bodySmall)))
          .toList(),
      onChanged: (val) { if (val != null) onChanged(val); },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final bool isFirst;
  final bool isLast;
  final Color color;
  final IconData icon;

  const _TimelineItem({
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 12 : null,
                  color: isFirst ? Colors.transparent : color.withValues(alpha: 0.3),
                  constraints: isFirst
                      ? null
                      : const BoxConstraints(minHeight: 12),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : color.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8F0EA)),
                ),
                child: Text(label, style: AppTextStyles.bodySmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final String emoji;
  final bool highlight;

  const _QuickStat({
    required this.value,
    required this.unit,
    required this.label,
    required this.emoji,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.info : AppColors.textPrimary,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: const Color(0xFFE8F0EA),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final PlantModel plant;
  final Future<void> Function() onWaterNow;
  final Future<void> Function() onEdit;

  const _BottomActionBar({
    required this.plant,
    required this.onWaterNow,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async => onEdit(),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async => onWaterNow(),
              icon: const Icon(Icons.water_drop_rounded, size: 16),
              label: const Text('Siram Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final PlantModel plant;
  final Future<void> Function() onToggleQuarantine;
  final Future<void> Function() onShare;
  final Future<void> Function() onDelete;

  const _MoreOptionsSheet({
    required this.plant,
    required this.onToggleQuarantine,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _OptionItem(
            icon: plant.status == PlantStatus.quarantine
                ? Icons.radio_button_checked_rounded
                : Icons.coronavirus_rounded,
            label: plant.status == PlantStatus.quarantine
                ? 'Keluar dari Karantina'
                : 'Tandai Karantina',
            color: plant.status == PlantStatus.quarantine
                ? AppColors.success
                : AppColors.quarantine,
            onTap: () async => onToggleQuarantine(),
          ),
          _OptionItem(
            icon: Icons.share_rounded,
            label: 'Bagikan Tanaman',
            color: AppColors.info,
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
          _OptionItem(
            icon: Icons.delete_rounded,
            label: 'Hapus Tanaman',
            color: AppColors.danger,
            onTap: () async => onDelete(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }
}
