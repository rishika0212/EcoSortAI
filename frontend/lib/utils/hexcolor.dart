import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    try {
      // Default color if parsing fails
      if (hexColor.isEmpty) {
        return 0xFF4CAF50; // Default green color
      }
      
      // Remove # if present
      final formatted = hexColor.toUpperCase().replaceAll("#", "");
      
      // Handle different hex formats
      if (formatted.length == 6) {
        return int.parse("FF$formatted", radix: 16);
      } else if (formatted.length == 8) {
        return int.parse(formatted, radix: 16);
      } else if (formatted.length == 3) {
        // Convert 3-digit hex to 6-digit
        final r = formatted[0];
        final g = formatted[1];
        final b = formatted[2];
        return int.parse("FF$r$r$g$g$b$b", radix: 16);
      } else {
        // Invalid format, return default green
        return 0xFF4CAF50;
      }
    } catch (e) {
      print("HexColor: Error parsing color '$hexColor': $e");
      return 0xFF4CAF50; // Default green color
    }
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}