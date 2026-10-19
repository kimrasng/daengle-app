import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

import 'tokens.dart';

const labelColor = DsColors.ink;
const secondaryLabel = DsColors.muted;
const brandColor = DsColors.sage;
const tint = DsColors.moss;
const groupedBackground = DsColors.canvas;
const fieldBackground = DsColors.field;
const tintBackground = DsColors.selected;
const separator = DsColors.line;

ThemeData buildAppTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: brandColor,
    secondary: brandColor,
    onSecondary: labelColor,
    secondaryContainer: tintBackground,
    onSecondaryContainer: tint,
    primary: tint,
    onPrimary: Colors.white,
    primaryContainer: tintBackground,
    onPrimaryContainer: tint,
    surface: Colors.white,
    onSurface: labelColor,
    error: DsColors.critical,
    onSurfaceVariant: secondaryLabel,
    outline: separator,
    outlineVariant: separator,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF7F8F4),
    surfaceContainer: groupedBackground,
    surfaceContainerHigh: groupedBackground,
    surfaceContainerHighest: const Color(0xFFE8ECE4),
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(DsRadius.button),
  );
  return ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
    fontFamily: 'packages/daengle_design/Pretendard',
    colorScheme: colors,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tint,
      selectionColor: brandColor.withValues(alpha: .25),
      selectionHandleColor: tint,
    ),
    scaffoldBackgroundColor: groupedBackground,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: labelColor,
        letterSpacing: -.7,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: labelColor,
        letterSpacing: -.6,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: labelColor,
        letterSpacing: -.4,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: labelColor,
        letterSpacing: -.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: labelColor,
        letterSpacing: -.2,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: labelColor,
        letterSpacing: -.2,
      ),
      bodySmall: TextStyle(fontSize: 13, height: 1.5, color: secondaryLabel),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: labelColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 24,
      toolbarHeight: 60,
      titleTextStyle: TextStyle(
        fontFamily: 'packages/daengle_design/Pretendard',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: labelColor,
      ),
      iconTheme: IconThemeData(color: labelColor, size: 24),
      actionsPadding: EdgeInsets.only(right: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 25,
          color: states.contains(WidgetState.selected)
              ? tint
              : const Color(0xFF8C9589),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'packages/daengle_design/Pretendard',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? tint : secondaryLabel,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRadius.panel),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      iconColor: secondaryLabel,
      minLeadingWidth: 28,
      horizontalTitleGap: 14,
      titleTextStyle: TextStyle(
        fontFamily: 'packages/daengle_design/Pretendard',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'packages/daengle_design/Pretendard',
        fontSize: 13,
        height: 1.5,
        color: secondaryLabel,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: separator,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      errorMaxLines: 3,
      fillColor: fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: secondaryLabel, fontSize: 15),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadius.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadius.control),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DsRadius.control),
        borderSide: const BorderSide(color: tint, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: const TextStyle(
          fontFamily: 'packages/daengle_design/Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: rounded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: separator),
        backgroundColor: Colors.white,
        foregroundColor: labelColor,
        textStyle: const TextStyle(
          fontFamily: 'packages/daengle_design/Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: rounded,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'packages/daengle_design/Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRadius.control),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: groupedBackground,
      selectedColor: tintBackground,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
        fontFamily: 'packages/daengle_design/Pretendard',
        fontSize: 13,
        color: secondaryLabel,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tint,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedTextStyle: const TextStyle(
        fontFamily: 'packages/daengle_design/Pretendard',
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? tint
            : const Color(0xFFD5DBD0),
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DsRadius.control),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? labelColor
              : secondaryLabel,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'packages/daengle_design/Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// Canonical package theme entry point. Font is resolved from this package.
abstract final class DaengleTheme {
  static ThemeData light() => buildAppTheme();
}
