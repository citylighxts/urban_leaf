import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/plant_model.dart';
import '../common/status_chip.dart';

class PlantListCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PlantListCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F0EA)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _EmojiAvatar(
                emoji: plant.emoji,
                status: plant.status,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: AppTextStyles.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PlantStatusChip(status: plant.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plant.type} · ${plant.methodLabel}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InfoTag(
                          icon: Icons.calendar_today_rounded,
                          label: '${plant.ageInDays} hari',
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _InfoTag(
                            icon: Icons.location_on_rounded,
                            label: plant.location,
                            expandText: true,
                          ),
                        ),
                        if (plant.isWateringDue) ...[
                          const SizedBox(width: 6),
                          _InfoTag(
                            icon: Icons.water_drop_rounded,
                            label: 'Siram',
                            highlight: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  final PlantStatus status;

  const _EmojiAvatar({required this.emoji, required this.status});

  Color get _borderColor => switch (status) {
        PlantStatus.healthy => AppColors.healthy,
        PlantStatus.needsAttention => AppColors.needsAttention,
        PlantStatus.quarantine => AppColors.quarantine,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final bool expandText;

  const _InfoTag({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.expandText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: highlight ? AppColors.info : AppColors.textSecondary,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: highlight
          ? BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        mainAxisSize: expandText ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: highlight ? AppColors.info : AppColors.textHint,
          ),
          const SizedBox(width: 3),
          expandText ? Flexible(child: textWidget) : textWidget,
        ],
      ),
    );
  }
}

// Grid variant for kebunku page
class PlantGridCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback onTap;

  const PlantGridCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F0EA)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        plant.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  PlantStatusChip(status: plant.status, small: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plant.name,
                style: AppTextStyles.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                plant.type,
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 11, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text(
                    '${plant.ageInDays}h',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: 8),
                  if (plant.isWateringDue) ...[
                    const Icon(Icons.water_drop_rounded,
                        size: 11, color: AppColors.info),
                    const SizedBox(width: 3),
                    const Text(
                      'Siram',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
