import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/services/wallpaper_actions.dart';

void main() {
  group('WallpaperActions', () {
    test('class exists and is accessible', () {
      expect(WallpaperActions, isA<Type>());
    });

    test('has handleHeartTap static method', () {
      // Verify the static method exists on the class without invoking it
      // (requires Supabase + BuildContext at runtime).
      expect(WallpaperActions.handleHeartTap, isA<Function>());
    });

    test('has onAuthSuccess static method', () {
      expect(WallpaperActions.onAuthSuccess, isA<Function>());
    });
  });
}
