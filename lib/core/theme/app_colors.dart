import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - forest green
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color secondary = Color(0xFF74C69D);
  static const Color accent = Color(0xFFD8F3DC);
  static const Color accentDeep = Color(0xFFB7E4C7);

  // Semantic colors
  static const Color warning = Color(0xFFFF8C00);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color danger = Color(0xFFDC3545);
  static const Color dangerLight = Color(0xFFFFE5E5);
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFFD4EDDA);
  static const Color info = Color(0xFF0D6EFD);
  static const Color infoLight = Color(0xFFCFE2FF);

  // Backgrounds
  static const Color background = Color(0xFFF4F9F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F7F2);
  static const Color cardShadow = Color(0x0F2D6A4F);

  // Text
  static const Color textPrimary = Color(0xFF1C2B20);
  static const Color textSecondary = Color(0xFF5C7061);
  static const Color textHint = Color(0xFF9BB5A0);

  // Plant status
  static const Color healthy = Color(0xFF28A745);
  static const Color healthyLight = Color(0xFFD4EDDA);
  static const Color needsAttention = Color(0xFFFF8C00);
  static const Color needsAttentionLight = Color(0xFFFFF3CD);
  static const Color quarantine = Color(0xFFDC3545);
  static const Color quarantineLight = Color(0xFFFFE5E5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
  );

  static const LinearGradient weatherGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
  );

  static const LinearGradient scannerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF1B4332)],
  );
}
