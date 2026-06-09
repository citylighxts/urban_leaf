import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/alert_model.dart';

class AlertBannerCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onMarkHandled;
  final VoidCallback? onDismiss;

  const AlertBannerCard({
    super.key,
    required this.alert,
    this.onMarkHandled,
    this.onDismiss,
  });

  (Color, Color, Color) get _colors => switch (alert.severity) {
        AlertSeverity.critical => (
            const Color(0xFFFFF0F0),
            const Color(0xFFFFD0D0),
            AppColors.danger,
          ),
        AlertSeverity.high => (
            const Color(0xFFFFF5F0),
            const Color(0xFFFFDEC0),
            AppColors.warning,
          ),
        AlertSeverity.medium => (
            const Color(0xFFFFFBE6),
            const Color(0xFFFFEA80),
            const Color(0xFFD4A017),
          ),
        AlertSeverity.low => (
            AppColors.infoLight,
            const Color(0xFFB8D4FF),
            AppColors.info,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, border, accent) = _colors;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      alert.typeEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _SeverityPill(
                            label: alert.severityLabel,
                            color: accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        style: AppTextStyles.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (alert.actionRequired.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        color: accent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alert.actionRequired,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accent.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${alert.plantEmoji} ${alert.plantName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (onMarkHandled != null)
                  _ActionButton(
                    label: 'Tandai Ditangani',
                    color: accent,
                    onTap: onMarkHandled!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
