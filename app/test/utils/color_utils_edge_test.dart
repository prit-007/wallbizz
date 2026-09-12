import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/utils/color_utils.dart';
import 'package:flutter/material.dart';

void main() {
  group('ColorUtils.hexToColor — edge cases', () {
    test('parses lowercase hex', () {
      final color = ColorUtils.hexToColor('#ff00ff');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(1.0, 0.01));
    });

    test('parses mixed case hex', () {
      final color = ColorUtils.hexToColor('#AaBbCc');
      expect(color.r, closeTo(170 / 255, 0.01));
      expect(color.g, closeTo(187 / 255, 0.01));
      expect(color.b, closeTo(204 / 255, 0.01));
    });

    test('parses hex without hash prefix', () {
      final color = ColorUtils.hexToColor('FF8800');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(136 / 255, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses 8-digit hex with alpha', () {
      final color = ColorUtils.hexToColor('#80FF0000');
      // 80 hex = 128 decimal, 128/255 ≈ 0.502
      expect(color.a, closeTo(128 / 255, 0.01));
      expect(color.r, closeTo(1.0, 0.01));
    });

    test('parses #000000 as black', () {
      final color = ColorUtils.hexToColor('#000000');
      expect(color.r, closeTo(0.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(0.0, 0.01));
    });

    test('parses #FFFFFF as white', () {
      final color = ColorUtils.hexToColor('#FFFFFF');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(1.0, 0.01));
      expect(color.b, closeTo(1.0, 0.01));
    });

    test('parses typical Wallhaven color #424153', () {
      final color = ColorUtils.hexToColor('#424153');
      expect(color, isA<Color>());
      expect(color.r, closeTo(66 / 255, 0.01));
      expect(color.g, closeTo(65 / 255, 0.01));
      expect(color.b, closeTo(83 / 255, 0.01));
    });

    test('parses #000001 (near-black)', () {
      final color = ColorUtils.hexToColor('#000001');
      expect(color.r, closeTo(0.0, 0.01));
      expect(color.g, closeTo(0.0, 0.01));
      expect(color.b, closeTo(1 / 255, 0.01));
    });
  });

  group('ColorUtils.withAlpha — edge cases', () {
    test('25% opacity', () {
      final color = ColorUtils.withAlpha(Colors.red, 0.25);
      expect(color.a, closeTo(0.25, 0.01));
    });

    test('75% opacity', () {
      final color = ColorUtils.withAlpha(Colors.blue, 0.75);
      expect(color.a, closeTo(0.75, 0.01));
    });

    test('preserves red channel', () {
      final color = ColorUtils.withAlpha(
        Color.fromRGBO(200, 100, 50, 1.0),
        0.5,
      );
      expect(color.r, closeTo(200 / 255, 0.01));
    });

    test('preserves green channel', () {
      final color = ColorUtils.withAlpha(
        Color.fromRGBO(200, 100, 50, 1.0),
        0.5,
      );
      expect(color.g, closeTo(100 / 255, 0.01));
    });

    test('preserves blue channel', () {
      final color = ColorUtils.withAlpha(
        Color.fromRGBO(200, 100, 50, 1.0),
        0.5,
      );
      expect(color.b, closeTo(50 / 255, 0.01));
    });

    test('0.0 opacity makes fully transparent', () {
      final color = ColorUtils.withAlpha(Colors.white, 0.0);
      expect(color.a, closeTo(0.0, 0.01));
    });

    test('1.0 opacity makes fully opaque', () {
      final color = ColorUtils.withAlpha(Colors.black, 1.0);
      expect(color.a, closeTo(1.0, 0.01));
    });

    test('works with custom colors', () {
      final input = ColorUtils.hexToColor('#1a1a2e');
      final faded = ColorUtils.withAlpha(input, 0.1);
      expect(faded.r, closeTo(input.r, 0.01));
      expect(faded.g, closeTo(input.g, 0.01));
      expect(faded.b, closeTo(input.b, 0.01));
      expect(faded.a, closeTo(0.1, 0.01));
    });
  });

  group('ColorUtils — integration', () {
    test('hexToColor then withAlpha round-trip', () {
      final original = ColorUtils.hexToColor('#FF8800');
      final faded = ColorUtils.withAlpha(original, 0.3);
      expect(faded.a, closeTo(0.3, 0.01));
      expect(faded.r, closeTo(1.0, 0.01));
      expect(faded.g, closeTo(136 / 255, 0.01));
      expect(faded.b, closeTo(0.0, 0.01));
    });

    test('hexToColor output is valid Color', () {
      for (final hex in [
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#1a1a2e',
        '#424153',
      ]) {
        final color = ColorUtils.hexToColor(hex);
        expect(color, isA<Color>());
      }
    });
  });
}
