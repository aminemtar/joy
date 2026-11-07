import 'package:flutter/material.dart';

/// JOY's shared bright, playful light-blue visual system.
abstract final class JoyTheme {
  static const ink = Color(0xFF102B55);
  static const muted = Color(0xFF5D789C);
  static const background = Color(0xFFEAF6FF);
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF5FBFF);
  static const border = Color(0xFFC8E3FA);
  static const accent = Color(0xFF087BFF);
  static const accentBright = Color(0xFF36A2FF);
  static const accentDeep = Color(0xFF0754C8);
  static const glow = Color(0x553B9DFF);

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43B7FF), Color(0xFF087BFF), Color(0xFF0754D6)],
  );
  static const panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5FBFF), Color(0xFFEAF6FF)],
  );

  static ThemeData get dark => ThemeData(
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
      primaryContainer: const Color(0xFFD7EDFF),
      onPrimaryContainer: accentDeep,
      secondary: const Color(0xFF35A9F5),
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
      secondaryContainer: const Color(0xFFE2F3FF),
      onSecondaryContainer: ink,
      surfaceContainerHighest: const Color(0xFFEAF5FF),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF123F7A),
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      elevation: 10,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: -.35,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFDCEAF5),
        disabledForegroundColor: muted,
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        elevation: 6,
        shadowColor: glow,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: .15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF8BCBFF), width: .8),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: surface,
        foregroundColor: accentDeep,
        minimumSize: const Size(48, 52),
        elevation: 4,
        shadowColor: const Color(0x333B8DCE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: border),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDeep,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: Color(0xFF9CCFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: accentDeep,
        backgroundColor: const Color(0xFFDFF1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: const Color(0xFFD8EEFF),
      disabledColor: const Color(0xFFEAF1F7),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: const TextStyle(color: accentDeep),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
      elevation: 2,
      pressElevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w700),
      prefixIconColor: accent,
      suffixIconColor: muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: accent, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE45D70)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE45D70), width: 1.7),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : const Color(0xFFD9EAF7),
      ),
      trackOutlineColor: WidgetStateProperty.all(border),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: const Color(0xFFD5E8F8),
      thumbColor: Colors.white,
      overlayColor: accent.withValues(alpha: .15),
      valueIndicatorColor: accentDeep,
      trackHeight: 5,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: Color(0xFFD5E8F8),
      circularTrackColor: Color(0xFFD5E8F8),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: accent,
      textColor: ink,
      subtitleTextStyle: TextStyle(color: muted, fontSize: 12),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x55356D9E),
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFB9DEFA), width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: ink,
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w900,
        letterSpacing: -.35,
      ),
      contentTextStyle: const TextStyle(
        color: muted,
        fontSize: 14,
        height: 1.55,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 22,
      showDragHandle: true,
      dragHandleColor: Color(0xFF9CCDF1),
      dragHandleSize: Size(44, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(color: Color(0xFFB9DEFA), width: 1),
      ),
      modalBarrierColor: Color(0x66305C88),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: .8),
  );

  /// The mini-game arena uses the same light palette for a consistent app.
  static ThemeData get arena => dark;
}
