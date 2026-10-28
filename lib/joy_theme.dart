import 'package:flutter/material.dart';

/// Sunny paper, punchy accents and soft raised surfaces throughout the party.
abstract final class JoyTheme {
  static const ink = Color(0xFF292744);
  static const muted = Color(0xFF716D87);
  static const paper = Color(0xFFFFFBF2);
  static const purple = Color(0xFF7053D6);
  static const pastels = [
    Color(0xFFFFE9B0),
    Color(0xFFDDF3EB),
    Color(0xFFE8E1FF),
    Color(0xFFFFE1E5),
    Color(0xFFDDF0FF),
  ];

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: paper,
    colorScheme: ColorScheme.fromSeed(seedColor: purple).copyWith(
      primary: purple,
      onPrimary: Colors.white,
      surface: paper,
      onSurface: ink,
      secondaryContainer: const Color(0xFFFFE9B0),
      onSecondaryContainer: ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE8E1FF),
      side: const BorderSide(color: Color(0xFFE6DFD4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: paper,
      showDragHandle: true,
    ),
  );

  static ThemeData get arena => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF161C36),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB5A1FF),
      brightness: Brightness.dark,
    ),
  );
}
