import 'package:flutter/material.dart';

/// Shared premium midnight-and-cobalt visual system for every JOY surface.
abstract final class JoyTheme {
  static const ink = Color(0xFFF4F7FF);
  static const muted = Color(0xFFA8B6D5);
  static const background = Color(0xFF080F22);
  static const surface = Color(0xFF111D36);
  static const raised = Color(0xFF192A4B);
  static const border = Color(0xFF2B416C);
  static const accent = Color(0xFF397BFF);
  static const accentBright = Color(0xFF78A8FF);
  static const accentDeep = Color(0xFF194CCB);
  static const glow = Color(0x55397BFF);

  static const blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF397BFF), Color(0xFF2458D8), Color(0xFF173B9C)],
  );
  static const panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3158), Color(0xFF132441), Color(0xFF101B32)],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    canvasColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accentBright,
      onPrimary: Colors.white,
      primaryContainer: accentDeep,
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFF8CC8FF),
      onSecondary: background,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
      secondaryContainer: raised,
      onSecondaryContainer: ink,
      surfaceContainerHighest: raised,
    ),
    scaffoldMessengerTheme: const ScaffoldMessengerThemeData(
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF20365E),
        contentTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        elevation: 12,
      ),
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
        fontWeight: FontWeight.w800,
        letterSpacing: -.35,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: raised,
        disabledForegroundColor: muted,
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        elevation: 7,
        shadowColor: glow,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: .15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: Color(0xFF80AFFF), width: .7),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: raised,
        foregroundColor: ink,
        minimumSize: const Size(48, 52),
        elevation: 5,
        shadowColor: const Color(0x55397BFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: Color(0xFF45649B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBright,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: muted,
        backgroundColor: raised.withValues(alpha: .72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent.withValues(alpha: .28),
      disabledColor: raised.withValues(alpha: .5),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false,
      elevation: 1,
      pressElevation: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF142440),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
      prefixIconColor: accentBright,
      suffixIconColor: muted,
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
        borderSide: const BorderSide(color: accentBright, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF718D)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF718D), width: 1.6),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? accent : raised,
      ),
      trackOutlineColor: WidgetStateProperty.all(border),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentBright,
      inactiveTrackColor: border,
      thumbColor: Colors.white,
      overlayColor: accent.withValues(alpha: .18),
      valueIndicatorColor: accentDeep,
      trackHeight: 4,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentBright,
      linearTrackColor: border,
      circularTrackColor: border,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: accentBright,
      textColor: ink,
      subtitleTextStyle: TextStyle(color: muted, fontSize: 12),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xCC000000),
      elevation: 26,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFF3B5C91), width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: ink,
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -.35,
      ),
      contentTextStyle: const TextStyle(
        color: muted,
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: 10,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 26,
      showDragHandle: true,
      dragHandleColor: Color(0xFF7895C4),
      dragHandleSize: Size(44, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(color: Color(0xFF3B5C91), width: 1),
      ),
      modalBarrierColor: Color(0xCC030817),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: .7),
  );

  static ThemeData get arena => dark;
}
