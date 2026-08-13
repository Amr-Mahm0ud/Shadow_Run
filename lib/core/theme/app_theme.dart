import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shadow / neon arcade visual identity (master plan §43).
class AppColors {
  AppColors._();

  /// Concept-sheet palette.
  static const Color voidBlack = Color(0xFF0A0E17);
  static const Color deepNavy = Color(0xFF0E1224);
  static const Color panel = Color(0xFF161B2E);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonMagenta = Color(0xFF7B2CFF);
  static const Color ember = Color(0xFFFF6A3D);
  static const Color gold = Color(0xFFFFB703);
  static const Color mist = Color(0xFFA7B0C0);
  static const Color danger = Color(0xFFFF3B3B);
  static const Color metal = Color(0xFFE8EDF5);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final display = GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme);
    final body = GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonMagenta,
        surface: AppColors.panel,
        error: AppColors.danger,
        onPrimary: AppColors.voidBlack,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: body.titleLarge?.copyWith(
          color: AppColors.mist,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: AppColors.mist, fontSize: 18),
        labelLarge: display.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: display.titleLarge?.copyWith(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.voidBlack,
          // Orbitron metrics need extra vertical room or labels clip.
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: display.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            height: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x33FFFFFF)),
    );
  }
}
