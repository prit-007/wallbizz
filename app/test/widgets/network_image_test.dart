import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wallbizz/widgets/network_image.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkImageWidget', () {
    testWidgets('renders widget tree without throwing', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NetworkImageWidget), findsOneWidget);
    });

    testWidgets('renders CachedNetworkImage on non-web platforms', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('applies BoxFit.cover by default', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.fit, BoxFit.cover);
    });

    testWidgets('accepts custom fit parameter', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
            fit: BoxFit.contain,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.fit, BoxFit.contain);
    });

    testWidgets('has a placeholder builder', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.placeholder, isNotNull);
    });

    testWidgets('has an errorWidget builder', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.errorWidget, isNotNull);
    });

    testWidgets('passes width to CachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
            width: 150,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.width, 150);
    });

    testWidgets('passes height to CachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const NetworkImageWidget(
            imageUrl: 'https://th.wallhaven.cc/small/test.jpg',
            height: 100,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.height, 100);
    });
  });
}
