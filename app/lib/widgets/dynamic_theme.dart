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
        color: ColorUtils.withAlpha(color, 0.1),
      ),
      child: child,
    );
  }
}
