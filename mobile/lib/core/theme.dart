import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF53B175);
  static const primaryDark = Color(0xFF3E9A5F);
  static const primarySoft = Color(0xFFEAF8E5);
  static const background = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const text = Color(0xFF181725);
  static const textMuted = Color(0xFF7C7C7C);
  static const border = Color(0xFFE6E8EC);
  static const red = Color(0xFFFF647C);
  static const redSoft = Color(0xFFFFECEF);
  static const orange = Color(0xFFFF9800);
  static const orangeSoft = Color(0xFFFFF0E5);
  static const blue = Color(0xFF6979F8);
  static const blueSoft = Color(0xFFEEF0FF);
  static const gold = Color(0xFFFFC107);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F1F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
