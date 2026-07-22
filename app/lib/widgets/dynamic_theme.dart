import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class DynamicTheme extends StatelessWidget {
  final String primaryColor;
  final Widget child;

  const DynamicTheme({
    super.key,
    required this.primaryColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.hexToColor(primaryColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
      ),
      child: child,
    );
  }
}
