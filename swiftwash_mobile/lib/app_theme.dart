import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color brandBlue = Color(0xFF00BFFF);
  static const Color brandGreen = Color(0xFF00FF7F);

  // UI Colors
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color actionBlue = Color(0xFF2397eb);
  static const Color background = Color(0xFFF8FAFC); // Light grey background
  static const Color divider = Color(0xFFEEF2F6);
  static const Color chevron = Color(0xFF98A2B3);

  // Gradients
  static const Gradient brandGradient = LinearGradient(
    colors: [brandBlue, brandGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient serviceCardGradient = LinearGradient(
    colors: [Color(0x12EAFBFF), Color(0x12EDFEEE)], // 7% opacity gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradients for Booking Process
  static const Gradient bookingButtonGradient = LinearGradient(
    colors: [Color(0xFF2397eb), Color(0xFF4aae5a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient bookingCardGradient = LinearGradient(
    colors: [Color(0xFF2397eb), Color(0xFF4aae5a)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradient for Delivery Date Button
  static const Gradient deliveryDateGradient = LinearGradient(
    colors: [Color(0xFF26A69A), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient for Tracking Card Border
  static const Gradient trackingCardBorderGradient = LinearGradient(
    colors: [Color(0xFF26A69A), AppColors.brandBlue, AppColors.brandGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Color for Swift Feature
  static const Color swiftOrange = Color(0xFFFFA726);

  // Colors for Time Slots
  static const Color selectedTimeFill = Color(0xFFE3F2FD);
  static const Color selectedTimeBorder = Color(0xFF2196F3);
}

class AppTypography {
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

class AppShadows {
  static final BoxShadow cardShadow = BoxShadow(
    color: const Color(0xFF0B1324).withOpacity(0.06),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.brandBlue,
      scaffoldBackgroundColor: AppColors.background, // Main background is grey
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, // AppBar is white
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}
