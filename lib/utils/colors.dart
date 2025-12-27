import 'package:flutter/material.dart';

class NoteColors {
  static const List<Color> presetColors = [
    Color(0xFFE0B0FF), // Light purple (like in image)
    Color(0xFFB5EAD7), // Mint green
    Color(0xFFB3E5FC), // Light blue
    Color(0xFFFFF9C4), // Light yellow/cream
    Color(0xFFFFB3D9), // Light pink
    Color(0xFFFFCCBC), // Light orange
    Color(0xFFFFFFFF), // White
    Color(0xFFC5E1A5), // Light green
    Color(0xFFE1BEE7), // Lavender
    Color(0xFFCFD8DC), // Light grey
  ];

  static Color getColorByIndex(int index) {
    return presetColors[index % presetColors.length];
  }

  static int getColorIndex(Color color) {
    return presetColors.indexOf(color);
  }
}

