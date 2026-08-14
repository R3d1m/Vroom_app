import 'package:flutter/material.dart';

class VroomColors {
  // Brand Swatches (Eco-Mobility Minimalist Palette)
  static const Color text = Color(0xFF091A10);          // Deep Forest Slate
  static const Color background = Color(0xFFF5FAF6);    // Clean Mint White
  static const Color surface = Color(0xFFFFFFFF);       // Crisp Studio White
  static const Color primary = Color(0xFF48C03D);       // Leaf Green (Primary CTA / Active Route)
  static const Color secondary = Color(0xFF6EE2CF);     // Soft Seafoam Aqua (Alternate Route / Badges)
  static const Color accent = Color(0xFF2EE385);        // Spring Emerald (Verified Badges / Success)
  
  // Neutrals & Utilities
  static const Color border = Color(0xFFE1ECE4);        // Subtle Divider
  static const Color surfaceMuted = Color(0xFFEAF5EE);  // Soft Pill Background
  static const Color textMuted = Color(0xFF5A7063);     // Secondary Text
  static const Color textLight = Color(0xFF8DA396);     // Placeholder Text
  
  // Status Colors
  static const Color danger = Color(0xFFE53935);        // Danger / Decline / SOS
  static const Color warning = Color(0xFFF59E0B);       // Warning / Attention
  static const Color bKash = Color(0xFFE2136E);         // bKash Brand Color
  static const Color nagad = Color(0xFFF7931E);         // Nagad Brand Color
}

class VroomTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: VroomColors.background,
      fontFamily: 'Segoe UI', // Standard crisp clean typography
      colorScheme: const ColorScheme.light(
        primary: VroomColors.primary,
        secondary: VroomColors.secondary,
        surface: VroomColors.surface,
        error: VroomColors.danger,
        onPrimary: Colors.white,
        onSecondary: VroomColors.text,
        onSurface: VroomColors.text,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VroomColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: VroomColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: VroomColors.text),
      ),
      cardTheme: CardThemeData(
        color: VroomColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VroomColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VroomColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VroomColors.text,
          side: const BorderSide(color: VroomColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VroomColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: VroomColors.textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VroomColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VroomColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VroomColors.primary, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: VroomColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
