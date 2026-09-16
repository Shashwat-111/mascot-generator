import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioColors {
  static const canvas = Color(0xFFF7F5EF);
  static const paper = Color(0xFFFFFCFA);
  static const ink = Color(0xFF171717);
  static const border = Color(0xFFDDD6C8);
  static const muted = Color(0xFF6F6B64);
  static const coral = Color(0xFFFF6B57);
  static const cobalt = Color(0xFF2F5CFF);
  static const lavender = Color(0xFFC9B8FF);
  static const mint = Color(0xFF3CB89A);
  static const butter = Color(0xFFF5D15A);
  static const errorWash = Color(0xFFFDE8E2);
  static const felt = Color(0xFFF3EDE3);
  static const card = paper;

  static const accents = <Color>[coral, cobalt, lavender, mint, butter, ink];
}

class StudioRadii {
  static const card = 12.0;
  static const sticker = 10.0;
}

class StudioType {
  static TextStyle wordmark() {
    return GoogleFonts.syne(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: StudioColors.ink,
      letterSpacing: -0.3,
    );
  }

  static TextStyle headline(double width) {
    final size = width >= 900
        ? 68.0
        : width >= 720
        ? 56.0
        : width >= 480
        ? 42.0
        : 34.0;
    return GoogleFonts.syne(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 0.96,
      letterSpacing: -2.2,
      color: StudioColors.ink,
    );
  }

  static TextStyle subhead(double width) {
    return GoogleFonts.figtree(
      fontSize: width >= 720 ? 20 : 17,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: StudioColors.muted,
    );
  }

  static TextStyle body() {
    return GoogleFonts.figtree(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: StudioColors.ink,
    );
  }

  static TextStyle hint() {
    return GoogleFonts.figtree(
      fontSize: 16,
      height: 1.5,
      color: StudioColors.muted,
    );
  }

  static TextStyle title(double width) {
    return GoogleFonts.syne(
      fontSize: width >= 720 ? 32 : 24,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.8,
      color: StudioColors.ink,
    );
  }

  static TextStyle chip() {
    return GoogleFonts.figtree(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: StudioColors.ink,
    );
  }

  static TextStyle captionName() {
    return GoogleFonts.syne(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: StudioColors.ink,
    );
  }

  static TextStyle captionMeta() {
    return GoogleFonts.figtree(
      fontSize: 13,
      height: 1.3,
      color: StudioColors.muted,
    );
  }

  static TextStyle status() {
    return GoogleFonts.figtree(
      fontSize: 14,
      height: 1.4,
      color: StudioColors.muted,
    );
  }
}

ThemeData buildStudioTheme() {
  final figtree = GoogleFonts.figtreeTextTheme();
  const radius = BorderRadius.all(Radius.circular(StudioRadii.card));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    splashColor: Colors.transparent,
    scaffoldBackgroundColor: StudioColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: StudioColors.ink,
      onPrimary: StudioColors.paper,
      secondary: StudioColors.cobalt,
      onSecondary: StudioColors.paper,
      tertiary: StudioColors.coral,
      surface: StudioColors.paper,
      onSurface: StudioColors.ink,
      outline: StudioColors.border,
      error: StudioColors.coral,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: StudioColors.ink,
      selectionColor: Color(0x332F5CFF),
      selectionHandleColor: StudioColors.cobalt,
    ),
    textTheme: figtree.copyWith(
      displayLarge: GoogleFonts.syne(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 0.98,
        color: StudioColors.ink,
        letterSpacing: -1.8,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: StudioColors.ink,
        letterSpacing: -1.2,
      ),
      headlineMedium: GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: StudioColors.ink,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: StudioColors.ink,
      ),
      bodyLarge: GoogleFonts.figtree(
        fontSize: 16,
        height: 1.5,
        color: StudioColors.ink,
      ),
      bodyMedium: GoogleFonts.figtree(
        fontSize: 15,
        height: 1.5,
        color: StudioColors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: StudioColors.ink,
        foregroundColor: StudioColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        minimumSize: const Size(44, 44),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StudioColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: StudioColors.border),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: GoogleFonts.figtree(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: StudioColors.muted,
        overlayColor: StudioColors.ink.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        minimumSize: const Size(44, 44),
        textStyle: GoogleFonts.figtree(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: StudioColors.paper,
      hintStyle: GoogleFonts.figtree(color: StudioColors.muted),
      contentPadding: const EdgeInsets.all(18),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: StudioColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: StudioColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: StudioColors.ink, width: 1.6),
      ),
    ),
  );
}
