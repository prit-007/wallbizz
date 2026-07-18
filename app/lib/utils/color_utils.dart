import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  static Color hexToColor(String hex) {
    try {
      hex = hex.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  static Color withAlpha(Color color, double opacity) {
    return Color.fromRGBO(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
      opacity,
    );
  }
}
