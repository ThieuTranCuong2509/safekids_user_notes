import 'package:flutter/material.dart';

/// Design tokens inspired by SafeKids enterprise color system.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2563EB); // SafeKids Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);

  static const Color bgCanvas = Color(0xFFF8FAFC); // Slate 50
  static const Color bgSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderFocused = Color(0xFF2563EB);

  static const Color error = Color(0xFFE11D48); // Rose 600
  static const Color errorBg = Color(0xFFFFF1F2);

  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color successBg = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
}
