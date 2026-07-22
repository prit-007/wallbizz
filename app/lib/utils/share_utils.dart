import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  static Future<void> shareWithWatermark({
    required String imageUrl,
    required BuildContext context,
  }) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      Share.share(
        'Check out this wallpaper from Wallbizz!\n$imageUrl',
        subject: 'Wallbizz Wallpapers',
      );
      return;
    }

    final codec = await ui.instantiateImageCodec(response.bodyBytes);
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
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: w * 0.055,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          fontFamily: 'Oswald',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final padding = w * 0.04;
    final tx = w - textPainter.width - padding;
    final ty = h - textPainter.height - padding;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tx - padding * 0.3, ty - padding * 0.3,
            textPainter.width + padding * 0.6, textPainter.height + padding * 0.6),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    textPainter.paint(canvas, Offset(tx, ty));

    final picture = recorder.endRecording();
    final watermarkedImage = await picture.toImage(w, h);
    final byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/wallbizz_share.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    originalImage.dispose();
    watermarkedImage.dispose();

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Wallbizz Wallpapers',
    );
  }
}
