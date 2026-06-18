import 'package:flutter/material.dart';
// import '../../../models/diagnosis_model.dart';
import '../../../models/plant_model.dart';
// import '../../../services/diagnosis_firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CareHistoryTab extends StatelessWidget {
  final PlantModel plant;
  
  const CareHistoryTab({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: plant.careHistory.isEmpty ? 1 : plant.careHistory.length,
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
                  color: isFirst ? Colors.transparent : color.withValues(alpha: 0.3),
                  constraints: isFirst
                      ? null
                      : const BoxConstraints(minHeight: 12),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : color.withValues(alpha: 0.3),
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
