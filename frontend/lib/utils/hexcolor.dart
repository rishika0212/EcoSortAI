 import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    final formatted = hexColor.toUpperCase().replaceAll("#", "");
    return int.parse("FF$formatted", radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}