import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  static Future<void> cleanOldShareFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.list();
      await for (final entity in files) {
        if (entity is File && entity.path.contains('wallbizz_share_')) {
          try {
            final stat = await entity.stat();
            if (DateTime.now().difference(stat.modified).inHours >= 1) {
              await entity.delete();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<void> shareWithWatermark({
    required String imageUrl,
    required BuildContext context,
    Uint8List? imageBytes,
  }) async {
    try {
      await cleanOldShareFiles();
      final bytes = imageBytes ?? await _fetchImageBytes(imageUrl);
      if (bytes == null) {
        _fallbackShare(imageUrl);
        return;
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final w = originalImage.width;
      final h = originalImage.height;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawImage(originalImage, Offset.zero, Paint());

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WALLBIZZ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: w * 0.045,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            fontFamily: 'Oswald',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final padding = w * 0.035;
      final tx = w - textPainter.width - padding;
      final ty = h - textPainter.height - padding;

      final bgRect = Rect.fromLTWH(
        tx - padding * 0.4,
        ty - padding * 0.3,
        textPainter.width + padding * 0.8,
        textPainter.height + padding * 0.6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(w * 0.015)),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(w * 0.015)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.002,
      );

      textPainter.paint(canvas, Offset(tx, ty));

      final picture = recorder.endRecording();
      final watermarkedImage = await picture.toImage(w, h);
      final byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/wallbizz_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      originalImage.dispose();
      watermarkedImage.dispose();

      HapticFeedback.lightImpact();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Wallbizz Wallpapers',
      );
    } catch (_) {
      _fallbackShare(imageUrl);
    }
  }

  static Future<Uint8List?> _fetchImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) return null;
    return response.bodyBytes;
  }

  static void _fallbackShare(String imageUrl) {
    HapticFeedback.lightImpact();
    Share.share(
      'Check out this wallpaper from Wallbizz!\n$imageUrl',
      subject: 'Wallbizz Wallpapers',
    );
  }
}
