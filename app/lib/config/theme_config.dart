import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeConfig {
  static const _darkModeKey = 'dark_mode';
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_darkModeKey);
    if (stored != null) {
      isDarkMode.value = stored;
    } else {
      isDarkMode.value = true;
    }
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    isDarkMode.value = value;
  }
}

class VivekColors extends ThemeExtension<VivekColors> {
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerLow;
  final Color onSurfaceSubtle;
  final Color onSurfaceFaint;
  final Color onSurfaceDim;
  final Color surfaceOverlay;
  final Color glassBorder;
  final Color glassBackground;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const VivekColors({
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerLow,
    required this.onSurfaceSubtle,
    required this.onSurfaceFaint,
    required this.onSurfaceDim,
    required this.surfaceOverlay,
    required this.glassBorder,
    required this.glassBackground,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  static const dark = VivekColors(
    surfaceContainer: Color(0xFF1C1C2E),
    surfaceContainerHigh: Color(0xFF252540),
    surfaceContainerLow: Color(0xFF151525),
    onSurfaceSubtle: Color(0xFF9D9BB5),
    onSurfaceFaint: Color(0xFF6B6980),
    onSurfaceDim: Color(0xFF48475A),
    surfaceOverlay: Color(0x0DFFFFFF),
    glassBorder: Color(0x26FFFFFF),
    glassBackground: Color(0x14FFFFFF),
    shimmerBase: Color(0xFF1C1C2E),
    shimmerHighlight: Color(0x19FFFFFF),
  );

  static const light = VivekColors(
    surfaceContainer: Color(0xFFEFEEF8),
    surfaceContainerHigh: Color(0xFFE4E3F0),
    surfaceContainerLow: Color(0xFFF5F4FF),
    onSurfaceSubtle: Color(0xFF6B6A80),
    onSurfaceFaint: Color(0xFF9D9BB0),
    onSurfaceDim: Color(0xFFBFBED0),
    surfaceOverlay: Color(0x0D000000),
    glassBorder: Color(0x1A000000),
    glassBackground: Color(0x0A000000),
    shimmerBase: Color(0xFFEFEEF8),
    shimmerHighlight: Color(0x0A000000),
  );

  @override
  ThemeExtension<VivekColors> copyWith({
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerLow,
    Color? onSurfaceSubtle,
    Color? onSurfaceFaint,
    Color? onSurfaceDim,
    Color? surfaceOverlay,
    Color? glassBorder,
    Color? glassBackground,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return VivekColors(
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      onSurfaceSubtle: onSurfaceSubtle ?? this.onSurfaceSubtle,
      onSurfaceFaint: onSurfaceFaint ?? this.onSurfaceFaint,
      onSurfaceDim: onSurfaceDim ?? this.onSurfaceDim,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBackground: glassBackground ?? this.glassBackground,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  VivekColors lerp(ThemeExtension<VivekColors>? other, double t) {
    if (other is! VivekColors) return this;
    return VivekColors(
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      surfaceContainerLow: Color.lerp(
        surfaceContainerLow,
        other.surfaceContainerLow,
        t,
      )!,
      onSurfaceSubtle: Color.lerp(onSurfaceSubtle, other.onSurfaceSubtle, t)!,
      onSurfaceFaint: Color.lerp(onSurfaceFaint, other.onSurfaceFaint, t)!,
      onSurfaceDim: Color.lerp(onSurfaceDim, other.onSurfaceDim, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
    );
  }
}

extension VivekTheme on BuildContext {
  VivekColors get vivek {
    return Theme.of(this).extension<VivekColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? VivekColors.dark
            : VivekColors.light);
  }
}
