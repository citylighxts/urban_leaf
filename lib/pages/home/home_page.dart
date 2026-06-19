import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/alert_generator_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/alert_model.dart';
import '../../models/plant_model.dart';
import '../../models/weather_model.dart';
import '../../services/alert_firestore_service.dart';
import '../../services/plant_firestore_service.dart';
import '../../services/plant_type_service.dart';
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

// ── Preset location ────────────────────────────────────────────────────────

class _LocationOption {
  final String name;
  final double lat;
  final double lng;
  const _LocationOption(this.name, this.lat, this.lng);
}

const _kCities = [
  _LocationOption('Jakarta Pusat', -6.2088, 106.8456),
  _LocationOption('Surabaya', -7.2575, 112.7521),
  _LocationOption('Bandung', -6.9175, 107.6191),
  _LocationOption('Medan', 3.5952, 98.6722),
  _LocationOption('Makassar', -5.1477, 119.4327),
  _LocationOption('Semarang', -6.9932, 110.4203),
  _LocationOption('Yogyakarta', -7.7956, 110.3695),
  _LocationOption('Palembang', -2.9761, 104.7754),
  _LocationOption('Tangerang', -6.1781, 106.6300),
  _LocationOption('Depok', -6.4025, 106.7942),
  _LocationOption('Bekasi', -6.2383, 106.9756),
  _LocationOption('Bogor', -6.5971, 106.8060),
  _LocationOption('Denpasar', -8.6705, 115.2126),
  _LocationOption('Balikpapan', -1.2675, 116.8289),
  _LocationOption('Banjarmasin', -3.3194, 114.5900),
];

class _HomePageState extends State<HomePage> {
  final _plantService = PlantFirestoreService();
  final _alertService = AlertFirestoreService();
  final _weatherService = WeatherService();

  WeatherModel? _weather;
  List<ForecastDayModel> _forecast = [];
  List<AlertModel> _alerts = [];
  bool _weatherLoading = true;
  String? _weatherError;
  bool _alertsGenerated = false;
  StreamSubscription<List<AlertModel>>? _alertSub;

  // null = use GPS; non-null = use preset city
  _LocationOption? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _alertSub = _alertService.watchAlerts().listen((alerts) {
      if (mounted) setState(() => _alerts = alerts);
    });
    _loadWeather();
  }


  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });
    try {
      final WeatherResult result;
      if (_selectedLocation != null) {
        result = await _weatherService.fetchWeatherForCoords(
          _selectedLocation!.lat,
          _selectedLocation!.lng,
          _selectedLocation!.name,
          forceRefresh: forceRefresh,
        );
      } else {
        result = await _weatherService.fetchWeather(forceRefresh: forceRefresh);
      }
      if (!mounted) return;
      setState(() {
        _weather = result.current;
        _forecast = result.forecast;
        _weatherLoading = false;
        _alertsGenerated = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherLoading = false;
        _weatherError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _onRefresh() => _loadWeather(forceRefresh: true);

  void _showLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(
        selected: _selectedLocation,
        onSelect: (loc) {
          setState(() {
            _selectedLocation = loc;
            _alertsGenerated = false;
          });
          _loadWeather(forceRefresh: true);
        },
      ),
    );
  }

  void _regenerateAlerts(List<PlantModel> plants) {
    if (_weather == null) return;
    final result = AlertGeneratorService.generate(
      weather: _weather!,
      forecast: _forecast,
      plants: plants,
    );

    // Hanya simpan alert baru ke Firestore. State _alerts dikendalikan stream.
    _alertService.saveAlerts(result.alerts).catchError((_) {});

    // Auto-flag healthy plants whose conditions exceed their tolerance.
    for (final id in result.plantIdsToFlag) {
      final plant = plants.where((p) => p.id == id).firstOrNull;
      if (plant == null) continue;
      _plantService.updatePlant(
        plant.copyWith(status: PlantStatus.needsAttention),
      ).catchError((_) => plant);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final String salut;
    if (hour >= 4 && hour < 10) {
      salut = 'Pagi';
    } else if (hour >= 10 && hour < 15) {
      // 14:30 → use minute check
      salut = (hour == 14 && DateTime.now().minute >= 30) ? 'Sore' : 'Siang';
    } else if (hour >= 15 && hour < 18) {
      salut = 'Sore';
    } else {
      salut = 'Malam';
    }
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.split(' ').first
        : user?.email?.split('@').first ?? 'Kamu';
    return 'Selamat $salut, $name 👋';
  }

  void _markAlertHandled(String id) {
    // State dikendalikan stream Firestore - cukup update Firestore.
    _alertService.updateStatus(id, AlertStatus.handled).catchError((_) {});
  }

  void _dismissAlert(String id) {
    _alertService.deleteAlert(id).catchError((_) {});
  }

  Future<void> _clearOldAlerts() async {
    await _alertService.deleteOldAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlantModel>>(
      stream: _plantService.watchPlants(),
      builder: (context, snapshot) {
        final plants = snapshot.data ?? const <PlantModel>[];

        // Generate alert baru setiap kali weather di-fetch ulang.
        if (snapshot.hasData && _weather != null && !_alertsGenerated) {
          _alertsGenerated = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) { if (mounted) _regenerateAlerts(plants); },
          );
        }

        final activeAlerts = _alerts
            .where((alert) => alert.status == AlertStatus.active)
            .toList();
        final urgentPlants = plants
            .where((p) => p.status != PlantStatus.healthy || p.isWateringDue)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // ── Location Picker ──
                      _LocationPill(
                        label: _selectedLocation?.name ?? 'Lokasi Saat Ini',
                        isGps: _selectedLocation == null,
                        onTap: _showLocationPicker,
                      ),
                      const SizedBox(height: 10),
                      // ── Weather Card ──
                      if (_weatherLoading)
                        _WeatherLoading()
                      else if (_weatherError != null)
                        _WeatherError(
                          message: _weatherError!,
                          onRetry: _loadWeather,
                        )
                      else if (_weather != null)
                        WeatherCard(
                          weather: _weather!,
                          forecast: _forecast,
                        ),
                      const SizedBox(height: 24),
                      SectionTitle(
                        title: 'Status Kebunmu',
                        actionLabel: 'Lihat semua',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      GardenStatusRow(
                        healthyCount: plants
                            .where((p) => p.status == PlantStatus.healthy)
                            .length,
                        needsAttentionCount: plants
                            .where(
                              (p) => p.status == PlantStatus.needsAttention,
                            )
                            .length,
                        quarantineCount: plants
                            .where((p) => p.status == PlantStatus.quarantine)
                            .length,
                      ),
                      if (snapshot.hasError) ...[
                        const SizedBox(height: 24),
                        const _InlineError(
                          message: 'Gagal memuat tanaman dari Firestore',
                        ),
                      ] else if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          plants.isEmpty) ...[
                        const SizedBox(height: 24),
                        const Center(child: CircularProgressIndicator()),
                      ] else ...[
                        if (activeAlerts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionTitle(
                            title: 'Peringatan Aktif',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AlertCountBadge(count: activeAlerts.length),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _clearOldAlerts,
                                  child: const Text(
                                    'Bersihkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...activeAlerts
                              .take(3)
                              .map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AlertBannerCard(
                                    alert: alert,
                                    onMarkHandled: () =>
                                        _markAlertHandled(alert.id),
                                    onDismiss: () => _dismissAlert(alert.id),
                                  ),
                                ),
                              ),
                          if (activeAlerts.length > 3)
                            _ShowMoreButton(
                              label:
                                  '+${activeAlerts.length - 3} peringatan lainnya',
                              onTap: () {},
                            ),
                        ],
                        if (urgentPlants.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle(title: 'Butuh Tindakan Segera'),
                          const SizedBox(height: 12),
                          ...urgentPlants
                              .take(3)
                              .map(
                                (plant) => Padding(
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
                                ),
                              ),
                        ],
                        if (urgentPlants.isEmpty) ...[
                          const SizedBox(height: 24),
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: _InlineEmpty(
                              message: 'Semua tanaman aman saat ini',
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 20,
      toolbarHeight: 60,
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
              Text(_greeting, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showNotificationsSheet(),
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: AppColors.textPrimary,
              ),
              if (_alerts.any((a) => a.status == AlertStatus.active))
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

  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertsSheet(
        alerts: _alerts,
        onMarkHandled: _markAlertHandled,
        onDismiss: _dismissAlert,
        onClearOld: _clearOldAlerts,
      ),
    );
  }
}

// ── Location Pill ─────────────────────────────────────────────────────────

class _LocationPill extends StatelessWidget {
  final String label;
  final bool isGps;
  final VoidCallback onTap;
  const _LocationPill(
      {required this.label, required this.isGps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE8E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGps ? Icons.my_location_rounded : Icons.location_on_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Location Picker Sheet ──────────────────────────────────────────────────

class _LocationPickerSheet extends StatelessWidget {
  final _LocationOption? selected;
  final ValueChanged<_LocationOption?> onSelect;
  const _LocationPickerSheet(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Lokasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // GPS option
                  _LocationTile(
                    icon: Icons.my_location_rounded,
                    name: 'Lokasi Saat Ini',
                    subtitle: 'Menggunakan GPS perangkat',
                    isSelected: selected == null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(null);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'KOTA LAINNYA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._kCities.map((city) => _LocationTile(
                        icon: Icons.location_on_rounded,
                        name: city.name,
                        subtitle:
                            '${city.lat.toStringAsFixed(2)}°, ${city.lng.toStringAsFixed(2)}°',
                        isSelected: selected?.name == city.name,
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(city);
                        },
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _LocationTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE8F0EA),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Weather Loading Skeleton ───────────────────────────────────────────────

class _WeatherLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: AppColors.weatherGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Mengambil data cuaca...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weather Error ──────────────────────────────────────────────────────────

class _WeatherError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WeatherError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gagal memuat cuaca',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

// ── Inline Error ───────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String message;

  const _InlineEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTextStyles.bodyMedium,
      textAlign: TextAlign.center,
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
                child: Text(plant.emoji, style: const TextStyle(fontSize: 22)),
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
                        : plant.latestConditionLabel,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alerts Bottom Sheet ────────────────────────────────────────────────────

class _AlertsSheet extends StatefulWidget {
  final List<AlertModel> alerts;
  final ValueChanged<String> onMarkHandled;
  final ValueChanged<String> onDismiss;
  final VoidCallback onClearOld;

  const _AlertsSheet({
    required this.alerts,
    required this.onMarkHandled,
    required this.onDismiss,
    required this.onClearOld,
  });

  @override
  State<_AlertsSheet> createState() => _AlertsSheetState();
}

class _AlertsSheetState extends State<_AlertsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return AppColors.danger;
      case AlertSeverity.high:
        return AppColors.warning;
      case AlertSeverity.medium:
        return const Color(0xFF0D6EFD);
      case AlertSeverity.low:
        return AppColors.textHint;
    }
  }

  Color _severityBg(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return AppColors.dangerLight;
      case AlertSeverity.high:
        return AppColors.warningLight;
      case AlertSeverity.medium:
        return AppColors.infoLight;
      case AlertSeverity.low:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.alerts
        .where((a) => a.status == AlertStatus.active)
        .toList()
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    final history = widget.alerts
        .where((a) => a.status != AlertStatus.active)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE8E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        widget.onClearOld();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Hapus riwayat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Aktif'),
                      if (active.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${active.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: 'Riwayat'),
              ],
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // ── Tab aktif ──
                  active.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('✅', style: TextStyle(fontSize: 40)),
                              SizedBox(height: 12),
                              Text(
                                'Tidak ada peringatan aktif',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kebunmu aman saat ini',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: active.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _AlertTile(
                            alert: active[i],
                            severityColor:
                                _severityColor(active[i].severity),
                            severityBg: _severityBg(active[i].severity),
                            onMarkHandled: () =>
                                widget.onMarkHandled(active[i].id),
                            onDismiss: () =>
                                widget.onDismiss(active[i].id),
                          ),
                        ),
                  // ── Tab riwayat ──
                  history.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada riwayat peringatan',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _AlertHistoryTile(
                            alert: history[i],
                            severityBg: _severityBg(history[i].severity),
                          ),
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

class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  final Color severityColor;
  final Color severityBg;
  final VoidCallback onMarkHandled;
  final VoidCallback onDismiss;

  const _AlertTile({
    required this.alert,
    required this.severityColor,
    required this.severityBg,
    required this.onMarkHandled,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(alert.typeEmoji,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(alert.plantEmoji,
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          alert.plantName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: severityBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert.severityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: severityColor,
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
          const SizedBox(height: 10),
          Text(
            alert.description,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          if (alert.actionRequired.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alert.actionRequired,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: Color(0xFFDDE8E0)),
                    foregroundColor: AppColors.textHint,
                  ),
                  child: const Text('Abaikan',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onMarkHandled,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Sudah Ditangani',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertHistoryTile extends StatelessWidget {
  final AlertModel alert;
  final Color severityBg;

  const _AlertHistoryTile(
      {required this.alert, required this.severityBg});

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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: severityBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child:
                  Text(alert.typeEmoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.plantEmoji} ${alert.plantName}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: alert.status == AlertStatus.handled
                  ? AppColors.successLight
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: alert.status == AlertStatus.handled
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
