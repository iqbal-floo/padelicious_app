import 'package:flutter/material.dart';

/// Palette lifted from the Padelicious design (Claude Design export).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF1A2D5A);
  static const navyLight = Color(0xFF24407A);
  static const teal = Color(0xFF3ABFBF);
  static const tealDark = Color(0xFF2A9A9A);
  static const green = Color(0xFF8DC63F);
  static const greenHover = Color(0xFF9FD946);
  static const greenText = Color(0xFF6A9A28);

  static const pageBg = Color(0xFFD8EEE4);
  static const surface = Color(0xFFF2FBF7);
  static const surfaceAlt = Color(0xFFE8F7F0);
  static const tealSurface = Color(0xFFE4F7F7);
  static const selectedTile = Color(0xFFEEF7E0);

  static const border = Color(0xFFCDE8D8);
  static const borderStrong = Color(0xFFB0D9C4);

  static const textMuted = Color(0xFF5A7A6A);
  static const textFaint = Color(0xFF8AAB98);
  static const error = Color(0xFFC0453F);
  static const gold = Color(0xFFE8B800);

  static const avatarBg = Color(0xFFDCEEFF);
  static const avatarFg = Color(0xFF1A5AAA);

  // Named individually (rather than as a single List<Color>) so each one is
  // usable inside a `const Player(...)` literal — const list indexing isn't
  // a constant expression in Dart.
  static const chipPairsBg0 = Color(0xFFDCEEFF);
  static const chipPairsBg1 = Color(0xFFD4F5E4);
  static const chipPairsBg2 = Color(0xFFFFF0DC);
  static const chipPairsBg3 = Color(0xFFEDE0FF);
  static const chipPairsBg4 = Color(0xFFFFDCDC);
  static const chipPairsBg5 = Color(0xFFDCF5FF);
  static const chipPairsBg6 = Color(0xFFE8FFD4);
  static const chipPairsBg7 = Color(0xFFFFF4DC);

  static const chipPairsFg0 = Color(0xFF1A5AAA);
  static const chipPairsFg1 = Color(0xFF1A7A44);
  static const chipPairsFg2 = Color(0xFF8A5500);
  static const chipPairsFg3 = Color(0xFF5A2AAA);
  static const chipPairsFg4 = Color(0xFFAA1A1A);
  static const chipPairsFg5 = Color(0xFF0A6A8A);
  static const chipPairsFg6 = Color(0xFF3A7A00);
  static const chipPairsFg7 = Color(0xFF8A6000);

  static const List<Color> chipPairsBg = [
    chipPairsBg0, chipPairsBg1, chipPairsBg2, chipPairsBg3,
    chipPairsBg4, chipPairsBg5, chipPairsBg6, chipPairsBg7,
  ];

  static const List<Color> chipPairsFg = [
    chipPairsFg0, chipPairsFg1, chipPairsFg2, chipPairsFg3,
    chipPairsFg4, chipPairsFg5, chipPairsFg6, chipPairsFg7,
  ];
}
