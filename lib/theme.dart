import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2D9D5F);
  static const primaryDark = Color(0xFF166534);
  static const primarySoft = Color(0xFFE8F6EE);
  static const bg = Color(0xFFF6FAF7);
  static const text = Color(0xFF272E29);
  static const muted = Color(0xFF748078);
  static const border = Color(0xFFCBD5CC);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const warn = Color(0xFFF59E0B);
  static const warnSoft = Color(0xFFFEF9C3);
  static const okSoft = Color(0xFFF0FDF4);
}

ThemeData buildTheme({required bool isDark, required Color seedColor}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: isDark ? Brightness.dark : Brightness.light,
    primary: seedColor,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : AppColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : AppColors.bg,
    cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      // 👈 FIXED: Increased vertical padding from 12 to 16 to fix text cut-off
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: seedColor, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: seedColor,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: seedColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      indicatorColor: seedColor.withAlpha(50),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}