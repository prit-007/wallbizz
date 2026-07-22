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
    final targetColor = ColorUtils.hexToColor(primaryColor);

    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: ColorTween(begin: Colors.black, end: targetColor),
      builder: (context, color, child) {
        final activeColor = color ?? Colors.transparent;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.4,
              colors: [
                activeColor.withValues(alpha: 0.25),
                activeColor.withValues(alpha: 0.08),
                Colors.black,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
