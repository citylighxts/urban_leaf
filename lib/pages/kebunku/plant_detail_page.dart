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
import 'widgets/care_history_tab.dart';
import 'widgets/diagnosis_tab.dart';

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
  late Stream<List<DiagnosisModel>> _diagnosisStream;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _tabController = TabController(length: 3, vsync: this);
    _diagnosisStream = _diagnosisService.watchDiagnosesByPlant(_plant.id);
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
          SliverToBoxAdapter(
            child: StreamBuilder<List<DiagnosisModel>>(
              stream: _diagnosisStream,
              // stream: _diagnosisService.watchDiagnosesByPlant(_plant.id),
              builder: (context, snapshot) {
                final diagnoses = snapshot.data ?? [];
                final effectiveStatus = diagnoses.isNotEmpty 
                    ? _plant.getEffectiveStatus(diagnoses) 
                    : _plant.status;
                return _buildInfoCard(effectiveStatus);
              }
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
          ),
        ],

        body: StreamBuilder<List<DiagnosisModel>>(
          stream: _diagnosisStream,
          builder: (context, snapshot) {
            // Ambil data langsung, tidak perlu simpan ke variabel state kelas
            final diagnoses = snapshot.data ?? [];

            // Gunakan list ini untuk menentukan status yang akan dikirim ke UI
            final effectiveStatus = diagnoses.isNotEmpty 
                ? _plant.getEffectiveStatus(diagnoses) 
                : _plant.status;
            final currentPlant = _plant.copyWith(status: effectiveStatus);

            // Masalah utama kedip-kedip adalah build ulang yang terlalu agresif.
            // Pastikan kita hanya me-return TabBarView saja.
            return TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(plant: currentPlant),
                CareHistoryTab(plant: currentPlant),
                DiagnosisStreamTab(
                  diagnoses: diagnoses,
                  diagnosisService: _diagnosisService,
                  plant: currentPlant,
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        plant: _plant,
        onCareAction: _showCareSheet,
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
        // Gunakan Center agar konten punya ruang
        child: Center( 
          child: SingleChildScrollView( // Tambahkan ini agar tidak overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50), // Beri jarak lebih banyak dari top
                Text(_plant.emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 8),
                Text(
                  _plant.name,
                  textAlign: TextAlign.center, // Tambahkan text align
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
                const SizedBox(height: 20), // Beri jarak bawah
              ],
            ),
          ),
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

  Widget _buildInfoCard(PlantStatus currentStatus) {
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
            PlantStatusChip(status: currentStatus),
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

  void _showCareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CareActionSheet(
        onCareSelected: (entry, isWatering) async {
          Navigator.pop(ctx);
          await _logCare(entry, isWatering: isWatering);
        },
      ),
    );
  }

  Future<void> _logCare(String historyEntry, {bool isWatering = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final updatedPlant = _plant.copyWith(
      status: isWatering
          ? (_plant.status == PlantStatus.quarantine
              ? PlantStatus.quarantine
              : PlantStatus.healthy)
          : _plant.status,
      nextWatering:
          isWatering ? now.add(const Duration(hours: 24)) : _plant.nextWatering,
      lastWateredAt: isWatering ? now : _plant.lastWateredAt,
      careHistory: [
        '$historyEntry - ${_formatDateTime(now)}',
        ..._plant.careHistory,
      ],
    );

    final savedPlant = await _plantService.updatePlant(updatedPlant);

    if (!mounted) return;
    setState(() => _plant = savedPlant);
    messenger.showSnackBar(
      SnackBar(
        content: Text('✅ $historyEntry berhasil dicatat!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
  final VoidCallback onCareAction;
  final Future<void> Function() onEdit;

  const _BottomActionBar({
    required this.plant,
    required this.onCareAction,
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
              onPressed: onCareAction,
              icon: const Icon(Icons.eco_rounded, size: 16),
              label: const Text('Catat Perawatan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final PlantModel plant;
  // final Future<void> Function() onToggleQuarantine;
  final Future<void> Function() onShare;
  final Future<void> Function() onDelete;

  const _MoreOptionsSheet({
    required this.plant,
    // required this.onToggleQuarantine,
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
          // _OptionItem(
          //   icon: plant.status == PlantStatus.quarantine
          //       ? Icons.radio_button_checked_rounded
          //       : Icons.coronavirus_rounded,
          //   label: plant.status == PlantStatus.quarantine
          //       ? 'Keluar dari Karantina'
          //       : 'Tandai Karantina',
          //   color: plant.status == PlantStatus.quarantine
          //       ? AppColors.success
          //       : AppColors.quarantine,
          //   onTap: () async => onToggleQuarantine(),
          // ),
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

class _CareOption {
  final String label;
  final String historyEntry;
  final IconData icon;
  final Color color;
  final bool isWatering;

  const _CareOption(
    this.label,
    this.historyEntry,
    this.icon,
    this.color, {
    this.isWatering = false,
  });
}

class _CareActionSheet extends StatelessWidget {
  final void Function(String entry, bool isWatering) onCareSelected;

  const _CareActionSheet({required this.onCareSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      const _CareOption('Penyiraman', 'Disiram', Icons.water_drop_rounded, Color(0xFF2196F3), isWatering: true),
      const _CareOption('Pemupukan', 'Dipupuk', Icons.science_rounded, Color(0xFFFF9800)),
      const _CareOption('Vitamin / Suplemen', 'Vitamin diberikan', Icons.spa_rounded, Color(0xFF9C27B0)),
      const _CareOption('Pemangkasan', 'Dipangkas', Icons.content_cut_rounded, Color(0xFF009688)),
      const _CareOption('Repotting', 'Repotting dilakukan', Icons.recycling_rounded, Color(0xFF795548)),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Catat Perawatan', style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          const Text(
            'Pilih jenis perawatan yang dilakukan',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          ...options.map(
            (opt) => _CareOptionTile(
              option: opt,
              onTap: () => onCareSelected(opt.historyEntry, opt.isWatering),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareOptionTile extends StatelessWidget {
  final _CareOption option;
  final VoidCallback onTap;

  const _CareOptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: option.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: option.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, size: 20, color: option.color),
              ),
              const SizedBox(width: 14),
              Text(option.label, style: AppTextStyles.labelLarge),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: option.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
