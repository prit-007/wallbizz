import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('delays execution by specified duration', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      final completer = Completer<void>();

      debouncer.run(() {
        completer.complete();
      });

      expect(completer.isCompleted, isFalse);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(completer.isCompleted, isTrue);
    });

    test('cancels previous call when run is called again quickly', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);
    });

    test('cancel prevents execution', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var called = false;

      debouncer.run(() => called = true);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(called, isFalse);
    });

    test('dispose prevents execution', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var called = false;

      debouncer.run(() => called = true);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(called, isFalse);
    });

    test('isActive is true while timer is running', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      expect(debouncer.isActive, isFalse);
      debouncer.run(() {});
      expect(debouncer.isActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(debouncer.isActive, isFalse);
    });

    test('uses default delay of 300ms', () async {
      final debouncer = Debouncer();
      var called = false;

      debouncer.run(() => called = true);

      // After 100ms should not have fired yet
      await Future.delayed(const Duration(milliseconds: 100));
      expect(called, isFalse);

      // After 350ms total should have fired
      await Future.delayed(const Duration(milliseconds: 300));
      expect(called, isTrue);
    });

    test('multiple independent debouncers do not interfere', () async {
      final d1 = Debouncer(delay: const Duration(milliseconds: 50));
      final d2 = Debouncer(delay: const Duration(milliseconds: 50));
      var count1 = 0;
      var count2 = 0;

      d1.run(() => count1++);
      d2.run(() => count2++);
      d1.run(() => count1++);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(count1, 1);
      expect(count2, 1);
    });
  });
}
