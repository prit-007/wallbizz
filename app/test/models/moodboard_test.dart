import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/models/moodboard.dart';

void main() {
  group('Moodboard constructor', () {
    test('creates instance with all required fields', () {
      final mb = Moodboard(
        id: 'mb-1',
        name: 'Favorites',
        itemCount: 5,
        createdAt: DateTime(2024, 6, 15),
      );

      expect(mb.id, 'mb-1');
      expect(mb.name, 'Favorites');
      expect(mb.itemCount, 5);
      expect(mb.createdAt, DateTime(2024, 6, 15));
    });

    test('defaults itemCount to 0', () {
      final mb = Moodboard(
        id: 'mb-2',
        name: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(mb.itemCount, 0);
    });
  });

  group('Moodboard.fromJson', () {
    test('parses all fields from Supabase row with int item_count', () {
      final json = {
        'id': 'mb-1',
        'name': 'Cyberpunk Vibes',
        'item_count': 12,
        'created_at': '2024-06-15T10:30:00Z',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.id, 'mb-1');
      expect(mb.name, 'Cyberpunk Vibes');
      expect(mb.itemCount, 12);
      expect(mb.createdAt, DateTime.utc(2024, 6, 15, 10, 30, 0));
    });

    test('parses item_count from Supabase count aggregate array', () {
      final json = {
        'id': 'mb-2',
        'name': 'Nature',
        'item_count': [
          {'count': 8},
        ],
        'created_at': '2024-06-15T10:30:00Z',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.itemCount, 8);
    });

    test('defaults itemCount to 0 when item_count is empty array', () {
      final json = {
        'id': 'mb-3',
        'name': 'Empty',
        'item_count': <Map<String, dynamic>>[],
        'created_at': '2024-06-15T10:30:00Z',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.itemCount, 0);
    });

    test('defaults itemCount to 0 when item_count is null', () {
      final json = {
        'id': 'mb-4',
        'name': 'Null Count',
        'created_at': '2024-06-15T10:30:00Z',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.itemCount, 0);
    });

    test('defaults itemCount to 0 when count key missing in aggregate', () {
      final json = {
        'id': 'mb-5',
        'name': 'Missing Count',
        'item_count': [
          {'other_field': 99},
        ],
        'created_at': '2024-06-15T10:30:00Z',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.itemCount, 0);
    });

    test('handles missing created_at gracefully', () {
      final json = {'id': 'mb-6', 'name': 'No Date'};

      final mb = Moodboard.fromJson(json);
      expect(mb.createdAt, isA<DateTime>());
    });

    test('handles invalid created_at string', () {
      final json = {
        'id': 'mb-7',
        'name': 'Bad Date',
        'created_at': 'not-a-date',
      };

      final mb = Moodboard.fromJson(json);
      expect(mb.createdAt, isA<DateTime>());
    });
  });
}
