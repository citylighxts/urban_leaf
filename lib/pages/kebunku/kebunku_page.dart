import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';
import '../../widgets/kebunku/plant_list_card.dart';
import 'add_edit_plant_page.dart';
import 'plant_detail_page.dart';

class KebunkuPage extends StatefulWidget {
  const KebunkuPage({super.key});

  @override
  State<KebunkuPage> createState() => _KebunkuPageState();
}

class _KebunkuPageState extends State<KebunkuPage> {
  late List<PlantModel> _plants;
  PlantStatus? _selectedFilter; // null = all
  bool _isGridView = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _plants = List.from(DummyData.plants);
  }

  List<PlantModel> get _filteredPlants {
    return _plants.where((p) {
      final matchesFilter =
          _selectedFilter == null || p.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _deleteConfirmDialog(PlantModel plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tanaman?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${plant.name} dari kebunmu? Semua riwayat akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _plants.removeWhere((p) => p.id == plant.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${plant.name} dihapus dari kebunmu'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlants;

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
                  _SearchBar(
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),
                  _FilterChips(
                    selected: _selectedFilter,
                    plants: _plants,
                    onSelect: (status) =>
                        setState(() => _selectedFilter = status),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${filtered.length} tanaman',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      _ViewToggle(
                        isGrid: _isGridView,
                        onToggle: (v) => setState(() => _isGridView = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(child: _EmptyState(hasFilter: _selectedFilter != null))
          else if (_isGridView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plant = filtered[index];
                    return PlantGridCard(
                      plant: plant,
                      onTap: () => _navigateToDetail(plant),
                    );
                  },
                  childCount: filtered.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final plant = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: Key(plant.id),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(),
                        confirmDismiss: (_) async {
                          _deleteConfirmDialog(plant);
                          return false;
                        },
                        child: PlantListCard(
                          plant: plant,
                          onTap: () => _navigateToDetail(plant),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPlant,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Tanaman',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _navigateToDetail(PlantModel plant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailPage(plant: plant)),
    );
  }

  void _navigateToAddPlant() async {
    final result = await Navigator.push<PlantModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPlantPage()),
    );
    if (result != null) {
      setState(() => _plants.insert(0, result));
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 20,
      toolbarHeight: 60,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kebunku 🌱',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(
            '${_plants.length} tanaman terdaftar',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Cari tanaman...',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final PlantStatus? selected;
  final List<PlantModel> plants;
  final ValueChanged<PlantStatus?> onSelect;

  const _FilterChips({
    required this.selected,
    required this.plants,
    required this.onSelect,
  });

  int _countByStatus(PlantStatus? s) =>
      s == null ? plants.length : plants.where((p) => p.status == s).length;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (null, 'Semua', '🌿'),
      (PlantStatus.healthy, 'Sehat', '✅'),
      (PlantStatus.needsAttention, 'Perlu Perhatian', '⚠️'),
      (PlantStatus.quarantine, 'Karantina', '🚨'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final (status, label, emoji) = f;
          final isSelected = selected == status;
          final count = _countByStatus(status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
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
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
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

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({required this.isGrid, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            icon: Icons.list_rounded,
            isActive: !isGrid,
            onTap: () => onToggle(false),
          ),
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            isActive: isGrid,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: isActive ? Colors.white : AppColors.textHint),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: AppColors.danger),
          SizedBox(height: 4),
          Text(
            'Hapus',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Tidak ada tanaman\ndengan filter ini' : 'Kebunmu masih kosong',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Coba ganti filter untuk melihat tanaman lainnya'
                : 'Mulai dengan menambahkan\ntanaman pertamamu!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
