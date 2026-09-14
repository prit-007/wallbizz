import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wallbizz/widgets/glass_action_button.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 80, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlassActionButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: () {},
            isDownloading: false,
            isDownloaded: false,
            label: 'DOWNLOAD',
            icon: HugeIcons.strokeRoundedDownload01,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DOWNLOAD'), findsOneWidget);
    });

    testWidgets('renders HugeIcon when not downloading', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: () {},
            isDownloading: false,
            isDownloaded: false,
            label: 'SAVE',
            icon: HugeIcons.strokeRoundedFavourite,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(HugeIcon), findsOneWidget);
    });

    testWidgets('renders CircularProgressIndicator when downloading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: null,
            isDownloading: true,
            isDownloaded: false,
            label: 'DOWNLOADING',
            icon: HugeIcons.strokeRoundedDownload01,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: () => pressed = true,
            isDownloading: false,
            isDownloaded: false,
            label: 'TAP ME',
            icon: HugeIcons.strokeRoundedDownload01,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('TAP ME'));
      expect(pressed, true);
    });

    testWidgets('has height of 56', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: () {},
            isDownloading: false,
            isDownloaded: false,
            label: 'LABEL',
            icon: HugeIcons.strokeRoundedDownload01,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(animatedContainer.constraints?.maxHeight, 56);
    });

    testWidgets('wraps in GestureDetector for tap animation', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          GlassActionButton(
            onPressed: () {},
            isDownloading: false,
            isDownloaded: false,
            label: 'X',
            icon: HugeIcons.strokeRoundedDownload01,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('FrostedCircleButton', () {
    testWidgets('renders HugeIcon', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          FrostedCircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(HugeIcon), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrapInApp(
          FrostedCircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FrostedCircleButton));
      expect(tapped, true);
    });

    testWidgets('renders as ClipOval', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          FrostedCircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('defaults to white icon color', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          FrostedCircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      final hugeIcon = tester.widget<HugeIcon>(find.byType(HugeIcon));
      expect(hugeIcon.color, Colors.white);
    });

    testWidgets('accepts custom iconColor', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          FrostedCircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onTap: () {},
            iconColor: Colors.red,
          ),
        ),
      );
      await tester.pump();

      final hugeIcon = tester.widget<HugeIcon>(find.byType(HugeIcon));
      expect(hugeIcon.color, Colors.red);
    });
  });
}
