import 'package:flutter/material.dart';

class AppTheme {
  // ---- Core surface colors ----
  static const Color navyBackground = Color(0xFF0B0F1C); // app background
  static const Color surfaceElevated = Color(0xFF121729); // app bar / nav bar
  static const Color cardBackground = Color(0xFF161D33); // default card
  static const Color cardBackgroundAlt = Color(0xFF1B2340); // hero / highlighted card

  // ---- Brand / accent ----
  static const Color primaryBlue = Color(0xFF4F8EF7);
  static const Color accentBlue = Color(0xFF7EB3FF);
  static const Color accentTeal = Color(0xFF2DD4BF);

  // ---- Semantic status colors ----
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  // ---- Text ----
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF8B96AD);
  static const Color textMuted = Color(0xFF5C6785);

  // Chart palette, reused across pie/bar charts for consistency
  static const List<Color> chartPalette = [
    primaryBlue,
    accentTeal,
    Color(0xFFA78BFA), // violet
    warning,
    Color(0xFFF472B6), // pink
    accentBlue,
  ];

  /// Returns a status color based on how close a value is to a budget/limit.
  /// ratio: value / limit (0.0 - 1.0+)
  static Color statusColorForRatio(double ratio) {
    if (ratio >= 1.0) return danger;
    if (ratio >= 0.8) return warning;
    return success;
  }

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D2A52), Color(0xFF141A2E)],
  );

  static BoxDecoration cardDecoration({bool highlighted = false}) {
    return BoxDecoration(
      color: highlighted ? cardBackgroundAlt : cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
    );
  }

  /// Glass-style decoration: translucent fill + soft border, meant to be used
  /// inside a ClipRRect > BackdropFilter(ImageFilter.blur(...)) wrapper.
  /// See GlassCard widget below for the ready-made wrapper.
  static BoxDecoration glassDecoration({double radius = 20, bool highlighted = false}) {
    return BoxDecoration(
      color: (highlighted ? primaryBlue : Colors.white).withValues(alpha: highlighted ? 0.10 : 0.05),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
    );
  }

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navyBackground,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentTeal,
      surface: cardBackground,
      error: danger,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.3,
      ),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      labelSmall: TextStyle(color: textMuted, fontSize: 11, letterSpacing: 0.4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navyBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: textPrimary,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceElevated,
      indicatorColor: primaryBlue.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? primaryBlue : textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? primaryBlue : textSecondary);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primaryBlue.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentBlue,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBlue, width: 1.4),
      ),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: const TextStyle(color: textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}