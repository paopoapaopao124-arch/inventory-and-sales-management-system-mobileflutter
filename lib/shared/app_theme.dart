
import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF061B2D);
  static const card = Color(0xFF0C2940);
  static const field = Color(0xFF10344C);
  static const emerald = Color(0xFF10D69A);
  static const muted = Color(0xFF9CB4C7);
  static const danger = Color(0xFFFF626F);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF24516B)),
        ),
      ),
    );
  }
}
