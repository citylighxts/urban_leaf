import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class GardenStatusRow extends StatelessWidget {
  final int healthyCount;
  final int needsAttentionCount;
  final int quarantineCount;

  const GardenStatusRow({
    super.key,
    required this.healthyCount,
    required this.needsAttentionCount,
    required this.quarantineCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = healthyCount + needsAttentionCount + quarantineCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusCard(
              count: healthyCount,
              label: 'Sehat',
              emoji: '✅',
              color: AppColors.healthy,
              bgColor: AppColors.healthyLight,
              flex: 2,
            ),
            const SizedBox(width: 10),
            _StatusCard(
              count: needsAttentionCount,
              label: 'Perlu Perhatian',
              emoji: '⚠️',
              color: AppColors.needsAttention,
              bgColor: AppColors.needsAttentionLight,
              flex: 3,
            ),
            const SizedBox(width: 10),
            _StatusCard(
              count: quarantineCount,
              label: 'Karantina',
              emoji: '🚨',
              color: AppColors.quarantine,
              bgColor: AppColors.quarantineLight,
              flex: 2,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressBar(
          healthyCount: healthyCount,
          needsAttentionCount: needsAttentionCount,
          quarantineCount: quarantineCount,
          total: total,
        ),
        const SizedBox(height: 4),
        Text(
          '$total tanaman terdaftar di kebunmu',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int count;
  final String label;
  final String emoji;
  final Color color;
  final Color bgColor;
  final int flex;

  const _StatusCard({
    required this.count,
    required this.label,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int healthyCount;
  final int needsAttentionCount;
  final int quarantineCount;
  final int total;

  const _ProgressBar({
    required this.healthyCount,
    required this.needsAttentionCount,
    required this.quarantineCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          if (healthyCount > 0)
            Expanded(
              flex: healthyCount,
              child: Container(height: 6, color: AppColors.healthy),
            ),
          if (needsAttentionCount > 0)
            Expanded(
              flex: needsAttentionCount,
              child: Container(height: 6, color: AppColors.needsAttention),
            ),
          if (quarantineCount > 0)
            Expanded(
              flex: quarantineCount,
              child: Container(height: 6, color: AppColors.quarantine),
            ),
        ],
      ),
    );
  }
}
