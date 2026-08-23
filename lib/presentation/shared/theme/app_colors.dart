import 'package:flutter/material.dart';
import 'package:mini_roulette/domain/value_objects/item_palette.dart';

/// 縁日の輪投げ台をイメージした漆黒・金・朱のパレット。
abstract final class AppColors {
  static const ink = Color(0xFF1A1214);
  static const felt = Color(0xFF24161A);
  static const surface = Color(0xFF322024);
  static const surfaceHigh = Color(0xFF3D282C);
  static const gold = Color(0xFFD4A017);
  static const goldLight = Color(0xFFE8C547);
  static const lacquer = Color(0xFFC41E3A);
  static const washi = Color(0xFFF3EDE3);
  static const muted = Color(0xFFB8A9A0);
  static const goldLine = Color(0x33D4A017);

  static List<Color> get itemPalette {
    return [for (final value in ItemPalette.values) Color(value)];
  }
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.ink,
    secondary: AppColors.lacquer,
    onSecondary: AppColors.washi,
    surface: AppColors.surface,
    onSurface: AppColors.washi,
    error: Color(0xFFE85D4C),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.washi,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.goldLine),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lacquer,
      foregroundColor: AppColors.washi,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.felt,
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.goldLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.goldLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
    ),
  );
}
