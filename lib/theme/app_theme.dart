import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color surface = const Color(0xFF060e20);
  static final Color onSurface = const Color(0xFFdee5ff);
  static final Color primary = const Color(0xFF9fa7ff);
  static final Color primaryContainer = const Color(0xFF8d98ff);
  static final Color secondary = const Color.fromARGB(255, 249, 255, 131);
  static final Color secondaryContainer = const Color(0xFF006b5f);
  static final Color tertiary = const Color(0xFFc180ff);
  static final Color error = const Color(0xFFff6e84);
  
  static final Color surfaceContainerLow = const Color(0xFF091328);
  static final Color surfaceContainerHigh = const Color(0xFF141f38);
  static final Color surfaceContainerHighest = const Color(0xFF192540);
  static final Color outlineVariant = const Color(0xFF7382A8);
  static final Color surfaceBright = const Color(0xFF1f2b49); // used with 40% opacity for glass

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.dark(
        surface: surface,
        onSurface: onSurface,
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        tertiary: tertiary,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          fontSize: 56, 
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 28, 
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 20, 
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18, 
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16, 
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14, 
          fontWeight: FontWeight.w400,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10, 
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5, // uppercase tracking
        ),
      ),
    );
  }
}
