import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/core/logger/logger.dart';

void main() {
  group('Logger', () {
    test('talker instance is initialized', () {
      expect(talker, isNotNull);
    });

    test('logInfo does not throw', () {
      expect(() => logInfo('test info'), returnsNormally);
    });

    test('logDebug does not throw', () {
      expect(() => logDebug('test debug'), returnsNormally);
    });

    test('logWarning does not throw', () {
      expect(() => logWarning('test warning'), returnsNormally);
    });

    test('logError does not throw', () {
      expect(() => logError('test error'), returnsNormally);
    });

    test('logError with exception does not throw', () {
      expect(
        () => logError(
          'error occurred',
          error: Exception('bad state'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });
}
