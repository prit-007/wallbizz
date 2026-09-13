import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveConfig {
  static const double compactWidth = 600;
  static const double mediumWidth = 900;
  static const double wideWidth = 1200;
  static const double ultraWideWidth = 1600;
  static const double maxContentWidth = 1400;

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) return MediaQuery.sizeOf(context).width > mediumWidth;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compactWidth && w < mediumWidth;
  }

  static bool isWide(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mediumWidth && w < ultraWideWidth;
  }

  static bool isUltraWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ultraWideWidth;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= ultraWideWidth) return 6;
    if (w >= wideWidth) return 5;
    if (w >= mediumWidth) return 4;
    if (w >= compactWidth) return 3;
    return 2;
  }
}

extension ResponsiveContext on BuildContext {
  bool get isDesktop => ResponsiveConfig.isDesktop(this);
  bool get isCompact => ResponsiveConfig.isCompact(this);
  bool get isMedium => ResponsiveConfig.isMedium(this);
  bool get isWide => ResponsiveConfig.isWide(this);
  bool get isUltraWide => ResponsiveConfig.isUltraWide(this);
  int get gridColumns => ResponsiveConfig.gridColumns(this);
}
