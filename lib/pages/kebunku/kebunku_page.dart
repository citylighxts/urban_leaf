import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';
import '../../widgets/kebunku/plant_list_card.dart';
import '../../services/plant_firestore_service.dart';
import 'add_edit_plant_page.dart';
import 'plant_detail_page.dart';

class KebunkuPage extends StatefulWidget {
  final PlantStatus? initialFilter;
  const KebunkuPage({super.key, this.initialFilter});

  @override
  State<KebunkuPage> createState() => _KebunkuPageState();
}

enum PlantSort { newest, oldest, nameAZ, nameZA, status, wateringDue }

extension PlantSortLabel on PlantSort {
  String get label => switch (this) {
    PlantSort.newest      => 'Terbaru Ditanam',
    PlantSort.oldest      => 'Terlama Ditanam',
    PlantSort.nameAZ      => 'Nama A–Z',
    PlantSort.nameZA      => 'Nama Z–A',
    PlantSort.status      => 'Butuh Perhatian',
    PlantSort.wateringDue => 'Siram Terdekat',
  };

  IconData get icon => switch (this) {
    PlantSort.newest      => Icons.fiber_new_rounded,
    PlantSort.oldest      => Icons.history_rounded,
    PlantSort.nameAZ      => Icons.sort_by_alpha_rounded,
    PlantSort.nameZA      => Icons.sort_by_alpha_rounded,
    PlantSort.status      => Icons.warning_amber_rounded,
    PlantSort.wateringDue => Icons.water_drop_rounded,
  };
}

int _statusPriority(PlantStatus s) => switch (s) {
  PlantStatus.quarantine     => 0,
  PlantStatus.needsAttention => 1,
  PlantStatus.healthy        => 2,
};

class _KebunkuPageState extends State<KebunkuPage> {
  final _plantService = PlantFirestoreService();
  late PlantStatus? _selectedFilter;
  PlantSort _selectedSort = PlantSort.newest;
  bool _isGridView = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  List<PlantModel> _filteredPlants(List<PlantModel> plants) {
    final filtered = plants.where((p) {
      final matchesFilter =
          _selectedFilter == null || p.status == _selectedFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    filtered.sort((a, b) => switch (_selectedSort) {
      PlantSort.newest      => b.plantedDate.compareTo(a.plantedDate),
      PlantSort.oldest      => a.plantedDate.compareTo(b.plantedDate),
      PlantSort.nameAZ      => a.name.compareTo(b.name),
      PlantSort.nameZA      => b.name.compareTo(a.name),
      PlantSort.status      => _statusPriority(a.status).compareTo(_statusPriority(b.status)),
      PlantSort.wateringDue => a.nextWatering.compareTo(b.nextWatering),
    });

    return filtered;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        selected: _selectedSort,
        onSelect: (sort) {
          setState(() => _selectedSort = sort);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<bool> _confirmDeletePlant(PlantModel plant) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tanaman?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${plant.name} dari kebunmu? Semua riwayat akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    try {
      await _plantService.deletePlant(plant.id);
      if (!mounted) return true;
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
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus tanaman: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlantModel>>(
      stream: _plantService.watchPlants(),
      builder: (context, snapshot) {
        final plants = snapshot.data ?? const [];
        final filtered = _filteredPlants(plants);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(plants.length),
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
                        plants: plants,
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
              if (snapshot.hasError)
                const SliverFillRemaining(
                  child: Center(child: Text('Gagal memuat data tanaman')),
                )
              else if (snapshot.connectionState == ConnectionState.waiting &&
                  plants.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(hasFilter: _selectedFilter != null),
                )
              else if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final plant = filtered[index];
                      return PlantGridCard(
                        plant: plant,
                        onTap: () => _navigateToDetail(plant),
                      );
                    }, childCount: filtered.length),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final plant = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(plant.id),
                          direction: DismissDirection.endToStart,
                          background: _DismissBackground(),
                          confirmDismiss: (_) => _confirmDeletePlant(plant),
                          child: PlantListCard(
                            plant: plant,
                            onTap: () => _navigateToDetail(plant),
                          ),
                        ),
                      );
                    }, childCount: filtered.length),
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
      },
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
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} ditambahkan ke kebunmu'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAppBar(int plantCount) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 20,
      toolbarHeight: 60,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kebunku 🌱',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text('$plantCount tanaman terdaftar', style: AppTextStyles.caption),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.sort_rounded,
            color: _selectedSort != PlantSort.newest
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
          onPressed: _showSortSheet,
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
                  horizontal: 14,
                  vertical: 8,
                ),
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
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
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
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : AppColors.textHint,
        ),
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

class _SortSheet extends StatelessWidget {
  final PlantSort selected;
  final ValueChanged<PlantSort> onSelect;

  const _SortSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Urutkan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...PlantSort.values.map((sort) {
              final isSelected = sort == selected;
              return ListTile(
                leading: Icon(
                  sort.icon,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 20,
                ),
                title: Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                    : null,
                onTap: () => onSelect(sort),
              );
            }),
          ],
        ),
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
            hasFilter
                ? 'Tidak ada tanaman\ndengan filter ini'
                : 'Kebunmu masih kosong',
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
