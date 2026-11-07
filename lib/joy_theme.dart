import 'package:flutter/material.dart';

/// JOY's cobalt-and-ice visual system. Game-library cards use the
/// dedicated card tokens below and intentionally retain their original look.
abstract final class JoyTheme {
  // App canvas and surfaces.
  static const background = Color(0xFF087BFF);
  static const canvas = Color(0xFFEAF6FF);
  static const surface = Color(0xFFF7FCFF);
  static const raised = Color(0xFFE8F5FF);
  static const ink = Color(0xFF102B52);
  static const muted = Color(0xFF58779B);
  static const border = Color(0xFFC8E3F7);

  // Brand and depth.
  static const accent = Color(0xFF087BFF);
  static const accentDeep = Color(0xFF0757C5);
  static const accentLight = Color(0xFF56B8FF);
  static const ice = Color(0xFFDDF1FF);
  static const highlight = Colors.white;
  static const shadow = Color(0x550044A8);
  static const shadowDeep = Color(0x77002E80);

  // Protected game-library card palette — unchanged from the original app.
  static const cardSurface = Color(0xFF131E38);
  static const cardRaised = Color(0xFF1A2948);
  static const cardBorder = Color(0xFF2A395A);
  static const cardInk = Color(0xFFF2F5FF);
  static const cardMuted = Color(0xFFA2ADCA);
  static const cardAccent = Color(0xFF91ACFF);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: ice,
      onPrimaryContainer: accentDeep,
      secondary: accentLight,
      onSecondary: ink,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
      secondaryContainer: raised,
      onSecondaryContainer: ink,
      error: const Color(0xFFD83D59),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: -.25,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB6D7F3),
        disabledForegroundColor: const Color(0xFFEEF8FF),
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 8,
        shadowColor: shadowDeep,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: .1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF6CC5FF), width: 1.2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDeep,
        backgroundColor: surface,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: border, width: 1.2),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: accentDeep,
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent,
      disabledColor: raised,
      side: const BorderSide(color: border, width: 1.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      showCheckmark: false,
      elevation: 3,
      pressElevation: 7,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 22,
      shadowColor: shadowDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: border, width: 1.2),
      ),
      titleTextStyle: const TextStyle(
        color: ink, fontSize: 21, fontWeight: FontWeight.w900,
      ),
      contentTextStyle: const TextStyle(
        color: muted, fontSize: 14, height: 1.5,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      showDragHandle: true,
      dragHandleColor: Color(0xFF9CC9EA),
      dragHandleSize: Size(42, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(color: border, width: 1),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : border,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: border,
      thumbColor: Colors.white,
      overlayColor: Color(0x22087BFF),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF12345F),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: border,
    ),
  );

  static ThemeData get arena => dark;
}
