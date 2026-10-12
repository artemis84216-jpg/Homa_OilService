import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color gold = Color(0xFFFFD700);
  static const Color accent = Color(0xFFFF8C00); // نارنجی
  static const Color textLight = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgDark,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: accent,
        surface: cardDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: gold, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: textLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: gold)),
      ),
    );
  }
}