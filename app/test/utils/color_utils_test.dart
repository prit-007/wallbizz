import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/utils/color_utils.dart';
import 'package:flutter/material.dart';

void main() {
  group('ColorUtils.hexToColor', () {
    test('parses 6-digit hex with #', () {
      final color = ColorUtils.hexToColor('#FF0000');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses 6-digit hex without #', () {
      final color = ColorUtils.hexToColor('00FF00');
      expect(color.r, closeTo(0.0, 0.01));
      expect(color.g, closeTo(1.0, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses 8-digit hex (with alpha)', () {
      final color = ColorUtils.hexToColor('#80FF0000');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses black', () {
      final color = ColorUtils.hexToColor('#000000');
      expect(color.r, closeTo(0.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses white', () {
      final color = ColorUtils.hexToColor('#ffffff');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(1.0, 0.01));
      expect(color.b, closeTo(1.0, 0.01));
    });

    test('parses common Wallhaven colors', () {
      final color1 = ColorUtils.hexToColor('#424153');
      expect(color1, isA<Color>());

      final color2 = ColorUtils.hexToColor('#ccb4b5');
      expect(color2, isA<Color>());

      final color3 = ColorUtils.hexToColor('#66cccc');
      expect(color3, isA<Color>());
    });
  });

  group('ColorUtils.withAlpha', () {
    test('applies 10% opacity', () {
      final original = ColorUtils.hexToColor('#FF0000');
      final faded = ColorUtils.withAlpha(original, 0.1);
      // Should produce a color with ~0.1 alpha
      expect(faded.a, closeTo(0.1, 0.01));
    });

    test('applies full opacity', () {
      final original = ColorUtils.hexToColor('#00FF00');
      final opaque = ColorUtils.withAlpha(original, 1.0);
      expect(opaque.r, closeTo(0.0, 0.01));
      expect(opaque.g, closeTo(1.0, 0.01));
      expect(opaque.a, closeTo(1.0, 0.01));
    });

    test('applies zero opacity (transparent)', () {
      final original = ColorUtils.hexToColor('#0000FF');
      final transparent = ColorUtils.withAlpha(original, 0.0);
      expect(transparent.a, closeTo(0.0, 0.01));
    });

    test('preserves RGB channels', () {
      final original = ColorUtils.hexToColor('#FF8800');
      final faded = ColorUtils.withAlpha(original, 0.5);
      expect(faded.r, closeTo(original.r, 0.01));
      expect(faded.g, closeTo(original.g, 0.01));
      expect(faded.b, closeTo(original.b, 0.01));
    });
  });
}
