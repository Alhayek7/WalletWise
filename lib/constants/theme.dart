import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0F4C3A);
  static const Color primaryLight = Color(0xFF1A6B4F);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5E6B8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF10B981);
  static const Color text = Color(0xFF1F2937);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}