import 'package:flutter/material.dart';

class YGColors {
  // Brand Colors - Light Theme
  static const Color lightBg = Color(0xfff7f2e8);
  static const Color lightSurface = Color(0xfffffcf6);
  static const Color lightSurface2 = Color(0xffefe8da);
  static const Color lightText = Color(0xff172222);
  static const Color lightMuted = Color(0xff6f7772);
  
  // Brand Colors - Dark Theme
  static const Color darkBg = Color(0xff121212);
  static const Color darkSurface = Color(0xff1e1e1e);
  static const Color darkSurface2 = Color(0xff2d2d2d);
  static const Color darkText = Color(0xfff8f5ef);
  static const Color darkMuted = Color(0xffa1a8a4);

  // Common Colors
  static const Color gold = Color(0xffd99412);
  static const Color gold2 = Color(0xffe2be37);
  static const Color red = Color(0xffef4458);
  static const Color green = Color(0xff34c779);
  static const Color lineLight = Color(0x18000000);
  static const Color lineDark = Color(0x1fffffff);
  static const Color shadowColor = Color(0x0a000000);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: YGColors.gold,
      scaffoldBackgroundColor: YGColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: YGColors.gold,
        secondary: YGColors.gold2,
        surface: YGColors.lightSurface,
        onSurface: YGColors.lightText,
        error: YGColors.red,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w900, color: YGColors.lightText),
        headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800, color: YGColors.lightText),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: YGColors.lightText),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: YGColors.lightMuted),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: YGColors.lightText),
        titleTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w900, color: YGColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: YGColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: YGColors.gold,
      scaffoldBackgroundColor: YGColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: YGColors.gold,
        secondary: YGColors.gold2,
        surface: YGColors.darkSurface,
        onSurface: YGColors.darkText,
        error: YGColors.red,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w900, color: YGColors.darkText),
        headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800, color: YGColors.darkText),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: YGColors.darkText),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: YGColors.darkMuted),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: YGColors.darkText),
        titleTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w900, color: YGColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: YGColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
    );
  }

  // Premium UI Box Decoration (Glassmorphism & Soft Shadow)
  static BoxDecoration premiumBoxDecoration({
    required bool isDark,
    double radius = 24,
    Color? customColor,
  }) {
    return BoxDecoration(
      color: customColor ?? (isDark ? YGColors.darkSurface : YGColors.lightSurface),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? YGColors.lineDark : YGColors.lineLight,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x1f000000) : YGColors.shadowColor,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
