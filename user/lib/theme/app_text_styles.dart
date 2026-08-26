import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display Scale (Outfit)
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  // Headline Scale (Outfit)
  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Title Scale (Inter)
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Body Scale (Inter)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Label & Button Scale (Inter)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Helper theme builder applying GoogleFonts Inter text theme
  static TextTheme createTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: displayLarge.copyWith(color: primaryTextColor),
      displayMedium: displayMedium.copyWith(color: primaryTextColor),
      headlineLarge: headlineLarge.copyWith(color: primaryTextColor),
      headlineMedium: headlineMedium.copyWith(color: primaryTextColor),
      titleLarge: titleLarge.copyWith(color: primaryTextColor),
      titleMedium: titleMedium.copyWith(color: primaryTextColor),
      bodyLarge: bodyLarge.copyWith(color: primaryTextColor),
      bodyMedium: bodyMedium.copyWith(color: secondaryTextColor),
      bodySmall: bodySmall.copyWith(color: secondaryTextColor),
      labelLarge: labelLarge.copyWith(color: primaryTextColor),
      labelSmall: labelSmall.copyWith(color: secondaryTextColor),
    );
  }
}
