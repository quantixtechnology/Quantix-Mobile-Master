import 'package:flutter/material.dart';
import 'brand_config.dart';

class ThemeFactory {
  static ThemeData light(BrandConfig brand) {
    final primary = _colorFromHex(brand.primaryColor);
    final secondary = _colorFromHex(brand.secondaryColor);
    final accent = _colorFromHex(brand.accentColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
        secondary: secondary,
        tertiary: accent,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    );
  }

  static ThemeData dark(BrandConfig brand) {
    final primary = _colorFromHex(brand.primaryColor);
    final secondary = _colorFromHex(brand.secondaryColor);
    final accent = _colorFromHex(brand.accentColor);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(secondary: secondary, tertiary: accent),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  static Color _colorFromHex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(6, '0');
    return Color(int.parse('FF$h', radix: 16));
  }
}
