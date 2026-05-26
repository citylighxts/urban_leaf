import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _StatsRow(),
                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Kebunmu',
                    icon: '🌿',
                    children: [
                      _ProfileTile(
                        icon: Icons.yard_rounded,
                        label: 'Total Tanaman',
                        value: '${DummyData.plants.length} tanaman',
                        color: AppColors.primary,
                      ),
                      _ProfileTile(
                        icon: Icons.check_circle_rounded,
                        label: 'Tanaman Sehat',
                        value: '${DummyData.healthyCount} tanaman',
                        color: AppColors.healthy,
                      ),
                      _ProfileTile(
                        icon: Icons.warning_rounded,
                        label: 'Perlu Perhatian',
                        value: '${DummyData.needsAttentionCount} tanaman',
                        color: AppColors.needsAttention,
                      ),
                      _ProfileTile(
                        icon: Icons.coronavirus_rounded,
                        label: 'Karantina',
                        value: '${DummyData.quarantineCount} tanaman',
                        color: AppColors.quarantine,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Notifikasi',
                    icon: '🔔',
                    children: [
                      _ToggleTile(
                        icon: Icons.notifications_rounded,
                        label: 'Alert Cuaca',
                        value: true,
                        color: AppColors.info,
                      ),
                      _ToggleTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Pengingat Siram',
                        value: true,
                        color: AppColors.info,
                      ),
                      _ToggleTile(
                        icon: Icons.coronavirus_rounded,
                        label: 'Alert Penyakit',
                        value: true,
                        color: AppColors.danger,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Pengaturan',
                    icon: '⚙️',
                    children: [
                      _ProfileTile(
                        icon: Icons.location_on_rounded,
                        label: 'Lokasi',
                        value: 'Kebayoran Baru, Jakarta',
                        color: AppColors.primary,
                      ),
                      _ProfileTile(
                        icon: Icons.thermostat_rounded,
                        label: 'Satuan Suhu',
                        value: 'Celsius (°C)',
                        color: AppColors.textSecondary,
                      ),
                      _ProfileTile(
                        icon: Icons.language_rounded,
                        label: 'Bahasa',
                        value: 'Indonesia',
                        color: AppColors.textSecondary,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SdgBadgesCard(),
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hana Azizah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Urban Farmer · Jakarta',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(value: '${DummyData.plants.length}', label: 'Tanaman'),
        const SizedBox(width: 12),
        _StatBox(
            value: '${DummyData.diagnoses.length}', label: 'Diagnosis AI'),
        const SizedBox(width: 12),
        _StatBox(
            value: '${DummyData.activeAlerts.length}', label: 'Alert Aktif'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8F0EA)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8F0EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.headingSmall),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(label, style: AppTextStyles.labelLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTextStyles.bodySmall),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textHint),
            ],
          ),
          onTap: () {},
        ),
        if (!isLast)
          const Divider(height: 1, indent: 68),
      ],
    );
  }
}

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final bool isLast;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
          title: Text(widget.label, style: AppTextStyles.labelLarge),
          trailing: Switch(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (!widget.isLast)
          const Divider(height: 1, indent: 68),
      ],
    );
  }
}

class _SdgBadgesCard extends StatelessWidget {
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
            '🌍 Kontribusi SDG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dengan urban farming, kamu berkontribusi pada:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SdgBadge(
                number: '11',
                label: 'Sustainable Cities',
                color: const Color(0xFFF89B24),
              ),
              const SizedBox(width: 8),
              _SdgBadge(
                number: '12',
                label: 'Responsible Production',
                color: const Color(0xFFBF8B2E),
              ),
              const SizedBox(width: 8),
              _SdgBadge(
                number: '13',
                label: 'Climate Action',
                color: const Color(0xFF3F7E44),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SdgBadge extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _SdgBadge({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Text(
              'SDG $number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
