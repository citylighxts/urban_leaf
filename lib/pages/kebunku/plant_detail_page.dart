import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/diagnosis_model.dart';
import '../../models/plant_model.dart';
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

  List<DiagnosisModel> get _plantDiagnoses => DummyData.diagnoses
      .where((d) => d.plantId == _plant.id)
      .toList();

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
            _DiagnosisTab(
              diagnoses: _plantDiagnoses,
              plant: _plant,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        plant: _plant,
        onWaterNow: () {
          setState(() {
            _plant = _plant.copyWith(
              nextWatering: DateTime.now().add(const Duration(hours: 24)),
              careHistory: [
                'Disiram — baru saja',
                ..._plant.careHistory,
              ],
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
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
          final result = await Navigator.push<PlantModel>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditPlantPage(plant: _plant),
            ),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MoreOptionsSheet(
        plant: _plant,
        onDelete: () {
          Navigator.pop(ctx);
          Navigator.pop(context, 'deleted');
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  const _TabBarDelegate({required this.tabController});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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
            children: [
              Text(plant.notes, style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _WeatherCompatibilityCard(plant: plant),
      ],
    );
  }
}

class _WeatherCompatibilityCard extends StatelessWidget {
  final PlantModel plant;
  const _WeatherCompatibilityCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final weather = DummyData.currentWeather;
    final isTempOk =
        weather.temperature >= plant.minTemp &&
        weather.temperature <= plant.maxTemp;
    final isHumidityOk =
        weather.humidity >= plant.minHumidity &&
        weather.humidity <= plant.maxHumidity;

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
          _CompatRow(
            label: 'Suhu ${weather.temperature.toStringAsFixed(0)}°C',
            isOk: isTempOk,
            note: isTempOk
                ? 'Aman (toleransi ${plant.minTemp.toStringAsFixed(0)}–${plant.maxTemp.toStringAsFixed(0)}°C)'
                : 'Melewati batas aman! Max ${plant.maxTemp.toStringAsFixed(0)}°C',
          ),
          const SizedBox(height: 8),
          _CompatRow(
            label: 'Kelembapan ${weather.humidity.toStringAsFixed(0)}%',
            isOk: isHumidityOk,
            note: isHumidityOk
                ? 'Aman (toleransi ${plant.minHumidity.toStringAsFixed(0)}–${plant.maxHumidity.toStringAsFixed(0)}%)'
                : 'Di luar batas aman',
          ),
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
              Text(label,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
              Text(note,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOk ? AppColors.textSecondary : AppColors.danger,
                  )),
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
      itemCount:
          plant.careHistory.isEmpty ? 1 : plant.careHistory.length,
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

class _DiagnosisTab extends StatelessWidget {
  final List<DiagnosisModel> diagnoses;
  final PlantModel plant;

  const _DiagnosisTab({required this.diagnoses, required this.plant});

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
            Text(
              'Tanaman kamu sehat!',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: diagnoses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _DiagnosisCard(diagnosis: diagnoses[index]),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  const _DiagnosisCard({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final (severityColor, severityBg) = switch (diagnosis.severity) {
      DiseaseSeverity.mild => (AppColors.success, AppColors.successLight),
      DiseaseSeverity.moderate => (
          AppColors.warning,
          AppColors.warningLight
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            style: AppTextStyles.bodySmall
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Text(diagnosis.description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 10),
          const Text('Solusi:', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          ...diagnosis.solutions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: AppTextStyles.bodySmall),
                    Expanded(
                      child: Text(s, style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            'Didiagnosis: ${_formatDate(diagnosis.diagnosedAt)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
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
                  color: isFirst ? Colors.transparent : color.withOpacity(0.3),
                  constraints: isFirst
                      ? null
                      : const BoxConstraints(minHeight: 12),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : color.withOpacity(0.3),
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
              color:
                  highlight ? AppColors.info : AppColors.textPrimary,
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
  final VoidCallback onWaterNow;
  final VoidCallback onEdit;

  const _BottomActionBar({
    required this.plant,
    required this.onWaterNow,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onWaterNow,
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
  final VoidCallback onDelete;

  const _MoreOptionsSheet({
    required this.plant,
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
            icon: Icons.coronavirus_rounded,
            label: 'Tandai Karantina',
            color: AppColors.quarantine,
            onTap: () => Navigator.pop(context),
          ),
          _OptionItem(
            icon: Icons.share_rounded,
            label: 'Bagikan Tanaman',
            color: AppColors.info,
            onTap: () => Navigator.pop(context),
          ),
          _OptionItem(
            icon: Icons.delete_rounded,
            label: 'Hapus Tanaman',
            color: AppColors.danger,
            onTap: onDelete,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          )),
      onTap: onTap,
    );
  }
}
