import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';
import '../../models/plant_type_model.dart';
import '../../services/plant_firestore_service.dart';
import '../../services/plant_type_service.dart';

class AddEditPlantPage extends StatefulWidget {
  final PlantModel? plant;             // null = add mode
  final String? preselectedTypeId;     // pre-select a plant type when coming from Rekomendasi tab

  const AddEditPlantPage({super.key, this.plant, this.preselectedTypeId});

  @override
  State<AddEditPlantPage> createState() => _AddEditPlantPageState();
}

class _AddEditPlantPageState extends State<AddEditPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final _plantService = PlantFirestoreService();
  final _plantTypeService = PlantTypeService();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;

  List<PlantTypeModel> _plantTypes = [];
  PlantTypeModel? _selectedPlantType;
  GrowingMethod _selectedMethod = GrowingMethod.hydroponic;
  DateTime _plantedDate = DateTime.now();
  bool _isSaving = false;
  bool _typesLoading = true;

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();
    final plant = widget.plant;
    _nameCtrl = TextEditingController(text: plant?.name ?? '');
    _locationCtrl = TextEditingController(text: plant?.location ?? '');
    _notesCtrl = TextEditingController(text: plant?.notes ?? '');

    if (plant != null) {
      _selectedMethod = plant.method;
      _plantedDate = plant.plantedDate;
    }

    _loadPlantTypes();
  }

  Future<void> _loadPlantTypes() async {
  // Pastikan status loading aktif saat proses berlangsung
    if (mounted) setState(() => _typesLoading = true);
    
    try {
      // 1. Pastikan data master sudah ada di Firestore (Seed dulu)
      await _plantTypeService.seedIfEmpty();
      
      // 2. Baru ambil datanya
      final types = await _plantTypeService.fetchAll();
      
      if (!mounted) return;
      
      setState(() {
        _plantTypes = types;
        _typesLoading = false; // Loading selesai
        
        if (_isEditing) {
          _selectedPlantType = types.where((t) => t.name == widget.plant!.type).firstOrNull;
        } else if (widget.preselectedTypeId != null) {
          _selectedPlantType = types.where((t) => t.id == widget.preselectedTypeId).firstOrNull;
        }
        
        _selectedPlantType ??= types.isNotEmpty ? types.first : null;
        
        if (!_isEditing && _nameCtrl.text.isEmpty && _selectedPlantType != null) {
          _nameCtrl.text = _selectedPlantType!.name;
        }
      });
    } catch (e) {
      print("DEBUG: Error saat memuat jenis tanaman: $e");
      if (mounted) {
        setState(() => _typesLoading = false);
        // Opsional: tampilkan snackbar jika gagal total
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar tanaman.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tanaman' : 'Tambah Tanaman'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isEditing ? 'Simpan' : 'Tambah',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder( // Menambahkan LayoutBuilder untuk presisi
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _typesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _EmojiSelector(
                          plantTypes: _plantTypes,
                          selected: _selectedPlantType,
                          onSelect: (t) => setState(() {
                            _selectedPlantType = t;
                            if (_nameCtrl.text.isEmpty) _nameCtrl.text = t.name;
                          }),
                        ),
                  if (_selectedPlantType != null) ...[
                    const SizedBox(height: 10),
                    _TolerancePreview(plantType: _selectedPlantType!),
                  ],
                  const SizedBox(height: 20),
                  _FormCard(
                    title: 'Informasi Dasar',
                    children: [
                      _InputLabel(label: 'Nama Tanaman'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Selada Hidroponik A',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      _InputLabel(label: 'Lokasi'),
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Balkon Lantai 2',
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Lokasi wajib diisi' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    title: 'Metode Tanam',
                    children: [
                      ...GrowingMethod.values.map(
                        (method) => _MethodRadioTile(
                          method: method,
                          isSelected: _selectedMethod == method,
                          onSelect: () => setState(() => _selectedMethod = method),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    title: 'Tanggal Tanam',
                    children: [
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDE8E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_plantedDate.day}/${_plantedDate.month}/${_plantedDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.edit_calendar_rounded,
                                color: AppColors.textHint,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    title: 'Catatan (opsional)',
                    children: [
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Catatan perawatan khusus, target panen, dll.',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing
                                  ? 'Simpan Perubahan'
                                  : 'Tambah ke Kebunku',
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _plantedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final id = widget.plant?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}';

    final plantType = _selectedPlantType;
    final result = PlantModel(
      id: id,
      name: _nameCtrl.text.trim(),
      type: plantType?.name ?? widget.plant?.type ?? '',
      emoji: plantType?.emoji ?? widget.plant?.emoji ?? '🌱',
      method: _selectedMethod,
      plantedDate: _plantedDate,
      location: _locationCtrl.text.trim(),
      status: widget.plant?.status ?? PlantStatus.healthy,
      nextWatering:
          widget.plant?.nextWatering ??
          DateTime.now().add(const Duration(hours: 24)),
      lastDiagnosis: widget.plant?.lastDiagnosis,
      careHistory: widget.plant?.careHistory ?? [],
      diseaseHistory: widget.plant?.diseaseHistory ?? [],
      minTemp: plantType?.minTemp ?? widget.plant?.minTemp ?? 15,
      maxTemp: plantType?.maxTemp ?? widget.plant?.maxTemp ?? 30,
      minHumidity: plantType?.minHumidity ?? widget.plant?.minHumidity ?? 40,
      maxHumidity: plantType?.maxHumidity ?? widget.plant?.maxHumidity ?? 80,
      notes: _notesCtrl.text.trim(),
    );

    try {
      final savedPlant = _isEditing
          ? await _plantService.updatePlant(result)
          : await _plantService.addPlant(result);

      if (!mounted) return;
      Navigator.pop(context, savedPlant);
    } catch (e, stackTrace) { // Tambahkan stackTrace
      print("ERROR: $e");
      print("STACKTRACE: $stackTrace"); // Ini akan menunjukkan baris mana yang error
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), // Tampilkan pesan error asli
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _EmojiSelector extends StatelessWidget {
  final List<PlantTypeModel> plantTypes;
  final PlantTypeModel? selected;
  final void Function(PlantTypeModel) onSelect;

  const _EmojiSelector({
    required this.plantTypes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InputLabel(label: 'Jenis Tanaman'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: plantTypes.map((t) {
            final isSelected = selected?.id == t.id;
            return GestureDetector(
              onTap: () => onSelect(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE0ECE4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MethodRadioTile extends StatelessWidget {
  final GrowingMethod method;
  final bool isSelected;
  final VoidCallback onSelect;

  static const Map<GrowingMethod, (String, String, String)> _info = {
    GrowingMethod.hydroponic: (
      '💧',
      'Hidroponik',
      'Tanpa media tanah, menggunakan larutan nutrisi',
    ),
    GrowingMethod.soil: (
      '🌍',
      'Media Tanah',
      'Menggunakan tanah biasa atau campuran',
    ),
    GrowingMethod.container: (
      '🪴',
      'Pot / Kontainer',
      'Dalam pot atau wadah terbatas',
    ),
    GrowingMethod.aeroponic: (
      '💨',
      'Aeroponik',
      'Akar digantung, nutrisi disemprotkan',
    ),
  };

  const _MethodRadioTile({
    required this.method,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, label, desc) = _info[method]!;
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFDDE8E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TolerancePreview extends StatelessWidget {
  final PlantTypeModel plantType;
  const _TolerancePreview({required this.plantType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7DFC4)),
      ),
      child: Row(
        children: [
          const Text('🌡️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${plantType.minTemp.toStringAsFixed(0)}–${plantType.maxTemp.toStringAsFixed(0)}°C',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          const Text('💧', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${plantType.minHumidity.toStringAsFixed(0)}–${plantType.maxHumidity.toStringAsFixed(0)}% RH',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            'Toleransi ${plantType.name}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormCard({required this.title, required this.children});

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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
