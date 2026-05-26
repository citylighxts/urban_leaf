import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';

class AddEditPlantPage extends StatefulWidget {
  final PlantModel? plant; // null = add mode

  const AddEditPlantPage({super.key, this.plant});

  @override
  State<AddEditPlantPage> createState() => _AddEditPlantPageState();
}

class _AddEditPlantPageState extends State<AddEditPlantPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;

  String _selectedType = 'Selada';
  String _selectedEmoji = '🥬';
  GrowingMethod _selectedMethod = GrowingMethod.hydroponic;
  DateTime _plantedDate = DateTime.now();

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();
    final plant = widget.plant;
    _nameCtrl = TextEditingController(text: plant?.name ?? '');
    _locationCtrl = TextEditingController(text: plant?.location ?? '');
    _notesCtrl = TextEditingController(text: plant?.notes ?? '');

    if (plant != null) {
      _selectedType = plant.type;
      _selectedEmoji = plant.emoji;
      _selectedMethod = plant.method;
      _plantedDate = plant.plantedDate;
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
            onPressed: _save,
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _EmojiSelector(
              selected: _selectedEmoji,
              onSelect: (emoji, type) => setState(() {
                _selectedEmoji = emoji;
                _selectedType = type;
                if (_nameCtrl.text.isEmpty) _nameCtrl.text = type;
              }),
            ),
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
                    prefixIcon: Icon(Icons.location_on_rounded,
                        color: AppColors.textHint, size: 18),
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
                    onSelect: () =>
                        setState(() => _selectedMethod = method),
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
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE8E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${_plantedDate.day}/${_plantedDate.month}/${_plantedDate.year}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_rounded,
                            color: AppColors.textHint, size: 16),
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
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Simpan Perubahan' : 'Tambah ke Kebunku',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.plant?.id ??
        'p${DateTime.now().millisecondsSinceEpoch}';

    final result = PlantModel(
      id: id,
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      emoji: _selectedEmoji,
      method: _selectedMethod,
      plantedDate: _plantedDate,
      location: _locationCtrl.text.trim(),
      status: widget.plant?.status ?? PlantStatus.healthy,
      nextWatering: widget.plant?.nextWatering ??
          DateTime.now().add(const Duration(hours: 24)),
      careHistory: widget.plant?.careHistory ?? [],
      diseaseHistory: widget.plant?.diseaseHistory ?? [],
      notes: _notesCtrl.text.trim(),
    );

    Navigator.pop(context, result);
  }
}

class _EmojiSelector extends StatelessWidget {
  final String selected;
  final void Function(String emoji, String type) onSelect;

  static const List<(String, String)> _types = [
    ('🥬', 'Selada'),
    ('🍅', 'Tomat'),
    ('🌶️', 'Cabai'),
    ('🌿', 'Kangkung'),
    ('🌱', 'Kemangi'),
    ('🍃', 'Bayam'),
    ('🥦', 'Brokoli'),
    ('🥕', 'Wortel'),
    ('🧅', 'Bawang'),
    ('🍆', 'Terong'),
    ('🥒', 'Timun'),
    ('🌸', 'Lainnya'),
  ];

  const _EmojiSelector({required this.selected, required this.onSelect});

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
          children: _types.map((t) {
            final (emoji, type) = t;
            final isSelected = selected == emoji;
            return GestureDetector(
              onTap: () => onSelect(emoji, type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.surface,
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
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      type,
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
    GrowingMethod.hydroponic: ('💧', 'Hidroponik', 'Tanpa media tanah, menggunakan larutan nutrisi'),
    GrowingMethod.soil: ('🌍', 'Media Tanah', 'Menggunakan tanah biasa atau campuran'),
    GrowingMethod.container: ('🪴', 'Pot / Kontainer', 'Dalam pot atau wadah terbatas'),
    GrowingMethod.aeroponic: ('💨', 'Aeroponik', 'Akar digantung, nutrisi disemprotkan'),
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
            color:
                isSelected ? AppColors.primary : const Color(0xFFDDE8E0),
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
                  Text(label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                  Text(desc,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontSize: 11)),
                ],
              ),
            ),
            Radio<GrowingMethod>(
              value: method,
              groupValue: isSelected ? method : null,
              onChanged: (_) => onSelect(),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
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
