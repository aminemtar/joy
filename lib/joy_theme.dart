import 'package:flutter/material.dart';

/// JOY visual language: bright sky surfaces, electric-blue actions and
/// tactile elevation. Game-library tiles intentionally keep their own styling.
abstract final class JoyTheme {
  static const ink = Color(0xFF102B4E);
  static const muted = Color(0xFF607A99);
  static const background = Color(0xFFEAF4FF);
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF3F8FF);
  static const border = Color(0xFFC9DDF4);
  static const accent = Color(0xFF087BFF);
  static const accentDeep = Color(0xFF075BC7);
  static const ice = Color(0xFFDCEEFF);
  static const sky = Color(0xFFB9DEFF);
  static const success = Color(0xFF168B72);
  static const warning = Color(0xFFB97812);
  static const danger = Color(0xFFD94B65);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    canvasColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: ice,
      onPrimaryContainer: const Color(0xFF123D70),
      secondary: const Color(0xFF32A8D8),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDDF5FF),
      onSecondaryContainer: const Color(0xFF14516D),
      tertiary: const Color(0xFF7A6BE8),
      onTertiary: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: const Color(0xFFDCE8F6),
      error: danger,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        backgroundColor: const WidgetStatePropertyAll(accent),
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(
          fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w800,
          letterSpacing: .15,
        )),
        elevation: const WidgetStatePropertyAll(5),
        shadowColor: const WidgetStatePropertyAll(Color(0x55075BC7)),
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: .12)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF5BA8FF), width: 1),
        )),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: surface,
        elevation: 4,
        shadowColor: const Color(0x332E6BA8),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDeep,
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: Color(0xFF9CCBFA), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: accentDeep,
        backgroundColor: ice,
        disabledForegroundColor: muted.withValues(alpha: .55),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: const Color(0xFFD5EAFE),
      disabledColor: const Color(0xFFEAF0F7),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto', color: ink, fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Roboto', color: accentDeep, fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted),
      prefixIconColor: accentDeep,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? Colors.white : const Color(0xFF9BB1C9)),
      trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? accent : const Color(0xFFD7E3F0)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: sky,
      thumbColor: accent,
      overlayColor: Color(0x22087BFF),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shadowColor: const Color(0x33234E7A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: border),
      ),
      titleTextStyle: const TextStyle(
        color: ink, fontSize: 21, fontWeight: FontWeight.w900,
      ),
      contentTextStyle: const TextStyle(color: muted, height: 1.5),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      showDragHandle: true,
      dragHandleColor: sky,
      dragHandleSize: Size(42, 4),
      elevation: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF173B63),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: ice,
    ),
  );

  /// Kept as a compatibility alias for existing screens; it is now light.
  static ThemeData get dark => light;
  static ThemeData get arena => light;
}
