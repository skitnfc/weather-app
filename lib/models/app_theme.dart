import 'package:flutter/material.dart';

class AppTheme {
  // Sky-inspired deep blue palette
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primaryMid = Color(0xFF0D2137);
  static const Color cardColor = Color(0xFF112240);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color accentTeal = Color(0xFF26C6DA);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF90CAF9);
  static const Color textMuted = Color(0xFF546E7A);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFEF5350);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryDark,
        colorScheme: const ColorScheme.dark(
          primary: accentBlue,
          secondary: accentTeal,
          surface: cardColor,
          onPrimary: primaryDark,
          onSecondary: primaryDark,
          onSurface: textPrimary,
        ),
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Georgia',
            color: textPrimary,
            fontWeight: FontWeight.w300,
          ),
          headlineLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(color: textPrimary),
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textMuted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textMuted),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: primaryMid,
          selectedItemColor: accentBlue,
          unselectedItemColor: textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );

  /// Колір картки в залежності від погоди
  static Color weatherGradientStart(String main) {
    switch (main) {
      case 'Clear':
        return const Color(0xFF1565C0);
      case 'Clouds':
        return const Color(0xFF37474F);
      case 'Rain':
      case 'Drizzle':
        return const Color(0xFF1A237E);
      case 'Thunderstorm':
        return const Color(0xFF212121);
      case 'Snow':
        return const Color(0xFF263238);
      default:
        return primaryMid;
    }
  }

  static Color weatherGradientEnd(String main) {
    switch (main) {
      case 'Clear':
        return const Color(0xFF0D47A1);
      case 'Clouds':
        return const Color(0xFF546E7A);
      case 'Rain':
      case 'Drizzle':
        return const Color(0xFF283593);
      case 'Thunderstorm':
        return const Color(0xFF311B92);
      case 'Snow':
        return const Color(0xFF37474F);
      default:
        return cardColor;
    }
  }

  static Color activityScoreColor(int score) {
    if (score >= 75) return success;
    if (score >= 50) return warning;
    return danger;
  }
}

class AppConstants {
  static const double borderRadius = 16.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
}
