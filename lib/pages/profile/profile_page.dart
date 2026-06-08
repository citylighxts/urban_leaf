import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';
import '../../pages/kebunku/kebunku_page.dart';
import '../../services/plant_firestore_service.dart';
import '../../services/user_profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = UserProfileService();
  final _plantService = PlantFirestoreService();

  UserProfile? _profile;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.fetchProfile();
    if (mounted) setState(() { _profile = profile; _profileLoading = false; });
  }

  Future<void> _showEditSheet() async {
    final p = _profile;
    if (p == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        initialName: p.displayName,
        initialCity: p.city,
        initialTitle: p.title,
        onSave: (name, city, title) => _profileService.updateProfile(
          displayName: name,
          city: city,
          title: title,
        ),
      ),
    );

    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlantModel>>(
      stream: _plantService.watchPlants(),
      builder: (context, snapshot) {
        final plants = snapshot.data ?? const [];
        final healthyCount      = plants.where((p) => p.status == PlantStatus.healthy).length;
        final attentionCount    = plants.where((p) => p.status == PlantStatus.needsAttention).length;
        final quarantineCount   = plants.where((p) => p.status == PlantStatus.quarantine).length;

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
                      _StatsRow(
                        plantCount: plants.length,
                        diagnosisCount: 0,
                        alertCount: attentionCount + quarantineCount,
                      ),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'Kebunmu',
                        icon: '🌿',
                        children: [
                          _ProfileTile(
                            icon: Icons.yard_rounded,
                            label: 'Total Tanaman',
                            value: '${plants.length} tanaman',
                            color: AppColors.primary,
                            onTap: _goToKebunku,
                          ),
                          _ProfileTile(
                            icon: Icons.check_circle_rounded,
                            label: 'Tanaman Sehat',
                            value: '$healthyCount tanaman',
                            color: AppColors.healthy,
                            onTap: _goToKebunku,
                          ),
                          _ProfileTile(
                            icon: Icons.warning_rounded,
                            label: 'Perlu Perhatian',
                            value: '$attentionCount tanaman',
                            color: AppColors.needsAttention,
                            onTap: _goToKebunku,
                          ),
                          _ProfileTile(
                            icon: Icons.coronavirus_rounded,
                            label: 'Karantina',
                            value: '$quarantineCount tanaman',
                            color: AppColors.quarantine,
                            isLast: true,
                            onTap: _goToKebunku,
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
                      _SdgBadgesCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToKebunku() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KebunkuPage()),
    );
  }

  Widget _buildAppBar() {
    final name  = _profile?.displayName ?? '';
    final city  = _profile?.city ?? '';
    final title = _profile?.title ?? '';
    final subtitle = [title, city].where((s) => s.isNotEmpty).join(' · ');

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
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 12),
              _profileLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                    )
                  : Text(
                      name.isNotEmpty ? name : '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              const SizedBox(height: 4),
              Text(
                subtitle.isNotEmpty ? subtitle : 'Urban Farmer',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
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
          onPressed: _showEditSheet,
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialCity;
  final String initialTitle;
  final Future<void> Function(String name, String city, String title) onSave;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialCity,
    required this.initialTitle,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _titleCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.initialName);
    _cityCtrl  = TextEditingController(text: widget.initialCity);
    _titleCtrl = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.onSave(_nameCtrl.text, _cityCtrl.text, _titleCtrl.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Edit Profil', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          _EditField(label: 'Nama', controller: _nameCtrl),
          const SizedBox(height: 12),
          _EditField(label: 'Kota', controller: _cityCtrl, hint: 'Jakarta'),
          const SizedBox(height: 12),
          _EditField(label: 'Sebutan', controller: _titleCtrl, hint: 'Urban Farmer'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _handleSave,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;

  const _EditField({required this.label, required this.controller, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int plantCount;
  final int diagnosisCount;
  final int alertCount;

  const _StatsRow({
    required this.plantCount,
    required this.diagnosisCount,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(value: '$plantCount', label: 'Tanaman'),
        const SizedBox(width: 12),
        _StatBox(value: '$diagnosisCount', label: 'Diagnosis AI'),
        const SizedBox(width: 12),
        _StatBox(value: '$alertCount', label: 'Butuh Perhatian'),
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
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
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
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
        ),
        if (!isLast) const Divider(height: 1, indent: 68),
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
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
          title: Text(widget.label, style: AppTextStyles.labelLarge),
          trailing: Switch(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        if (!widget.isLast) const Divider(height: 1, indent: 68),
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
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SdgBadge(number: '11', label: 'Sustainable Cities',        color: const Color(0xFFF89B24)),
              const SizedBox(width: 8),
              _SdgBadge(number: '12', label: 'Responsible Production',    color: const Color(0xFFBF8B2E)),
              const SizedBox(width: 8),
              _SdgBadge(number: '13', label: 'Climate Action',            color: const Color(0xFF3F7E44)),
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

  const _SdgBadge({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.6)),
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
                color: Colors.white.withValues(alpha: 0.7),
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
