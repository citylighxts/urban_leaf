import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/alert_model.dart';
import '../../models/plant_model.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/home/alert_banner_card.dart';
import '../../widgets/home/garden_status_row.dart';
import '../../widgets/home/weather_card.dart';
import '../kebunku/plant_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<AlertModel> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = List.from(DummyData.alerts);
  }

  void _markAlertHandled(String id) {
    setState(() {
      final idx = _alerts.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _alerts[idx] = _alerts[idx].copyWith(status: AlertStatus.handled);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts =
        _alerts.where((a) => a.status == AlertStatus.active).toList();
    final urgentPlants = DummyData.urgentPlants;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  WeatherCard(
                    weather: DummyData.currentWeather,
                    forecast: DummyData.forecast,
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'Status Kebunmu',
                    actionLabel: 'Lihat semua',
                    onAction: () {},
                  ),
                  const SizedBox(height: 12),
                  GardenStatusRow(
                    healthyCount: DummyData.healthyCount,
                    needsAttentionCount: DummyData.needsAttentionCount,
                    quarantineCount: DummyData.quarantineCount,
                  ),
                  if (activeAlerts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionTitle(
                      title: 'Peringatan Aktif',
                      trailing: _AlertCountBadge(count: activeAlerts.length),
                    ),
                    const SizedBox(height: 12),
                    ...activeAlerts
                        .take(3)
                        .map((alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AlertBannerCard(
                                alert: alert,
                                onMarkHandled: () =>
                                    _markAlertHandled(alert.id),
                              ),
                            ))
                        .toList(),
                    if (activeAlerts.length > 3)
                      _ShowMoreButton(
                        label:
                            '+${activeAlerts.length - 3} peringatan lainnya',
                        onTap: () {},
                      ),
                  ],
                  if (urgentPlants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionTitle(
                      title: 'Butuh Tindakan Segera',
                    ),
                    const SizedBox(height: 12),
                    ...urgentPlants
                        .take(3)
                        .map((plant) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UrgentPlantCard(
                                plant: plant,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlantDetailPage(plant: plant),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                  const SizedBox(height: 24),
                  _QuickActionsRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 20,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UrbanLeaf AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Selamat pagi, Hana 👋',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              const Icon(Icons.notifications_rounded,
                  color: AppColors.textPrimary),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _AlertCountBadge extends StatelessWidget {
  final int count;
  const _AlertCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count Aktif',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShowMoreButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8F0EA)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _UrgentPlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;
  const _UrgentPlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8F0EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(plant.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    plant.status == PlantStatus.quarantine
                        ? plant.lastDiagnosis ?? 'Karantina'
                        : plant.isWateringDue
                            ? 'Jadwal penyiraman terlewat'
                            : 'Perlu perhatian',
                    style: AppTextStyles.bodySmall,
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Aksi Cepat'),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              emoji: '📷',
              label: 'Scan Penyakit',
              color: const Color(0xFFE8F4FD),
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickAction(
              emoji: '💧',
              label: 'Siram Tanaman',
              color: const Color(0xFFEDF7ED),
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickAction(
              emoji: '➕',
              label: 'Tambah Tanaman',
              color: const Color(0xFFF3EDF7),
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _QuickAction(
              emoji: '📊',
              label: 'Lihat Laporan',
              color: const Color(0xFFFFF8E1),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
