import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/plant_model.dart';

class PlantStatusChip extends StatelessWidget {
  final PlantStatus status;
  final bool small;

  const PlantStatusChip({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      PlantStatus.healthy => ('Sehat', AppColors.healthyLight, AppColors.healthy),
      PlantStatus.needsAttention => (
          'Perlu Perhatian',
          AppColors.needsAttentionLight,
          AppColors.needsAttention,
        ),
      PlantStatus.quarantine => ('Karantina', AppColors.quarantineLight, AppColors.quarantine),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class SeverityChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const SeverityChip({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
