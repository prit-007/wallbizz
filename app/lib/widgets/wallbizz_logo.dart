import 'package:flutter/material.dart';

class WallbizzLogo extends StatelessWidget {
  const WallbizzLogo({super.key, this.size = 72, this.showText = false});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(size * 0.2),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _WLogoPainter(color: cs.onSurface),
            size: Size(size, size),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.25),
          Text(
            'WALLBIZZ',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.04,
              color: cs.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

class _WLogoPainter extends CustomPainter {
  const _WLogoPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final pad = w * 0.22;

    path.moveTo(pad, h * 0.28);
    path.lineTo(w * 0.35, h * 0.78);
    path.lineTo(w * 0.5, h * 0.38);
    path.lineTo(w * 0.65, h * 0.78);
    path.lineTo(w - pad, h * 0.28);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
