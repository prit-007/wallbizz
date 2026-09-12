import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:vivek_app/core/updates/update_checker.dart';

void main() {
  group('AppVersion', () {
    test('parses major.minor.patch', () {
      final v = AppVersion.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('strips build metadata after +', () {
      final v = AppVersion.parse('1.2.3+456');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('strips pre-release suffix', () {
      final v = AppVersion.parse('1.2.3-beta');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('handles single digit version', () {
      final v = AppVersion.parse('2');
      expect(v.major, 2);
      expect(v.minor, 0);
      expect(v.patch, 0);
    });

    test('handles empty string', () {
      final v = AppVersion.parse('');
      expect(v.major, 0);
      expect(v.minor, 0);
      expect(v.patch, 0);
    });

    test('toString returns formatted version', () {
      final v = AppVersion(1, 2, 3);
      expect(v.toString(), '1.2.3');
    });
  });

  group('AppVersion.isNewerThan', () {
    test('newer major is newer', () {
      expect(AppVersion(2, 0, 0).isNewerThan(AppVersion(1, 9, 9)), true);
    });

    test('newer minor is newer', () {
      expect(AppVersion(1, 3, 0).isNewerThan(AppVersion(1, 2, 9)), true);
    });

    test('newer patch is newer', () {
      expect(AppVersion(1, 2, 4).isNewerThan(AppVersion(1, 2, 3)), true);
    });

    test('same version is not newer', () {
      expect(AppVersion(1, 2, 3).isNewerThan(AppVersion(1, 2, 3)), false);
    });

    test('older version is not newer', () {
      expect(AppVersion(1, 1, 0).isNewerThan(AppVersion(1, 2, 0)), false);
    });
  });

  group('UpdateChecker', () {
    test('returns UpdateInfo when newer version exists', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'draft': false,
              'prerelease': false,
              'body': '- New feature\n- Bug fix',
              'html_url':
                  'https://github.com/prit-007/wallbizz/releases/tag/v2.0.0',
              'published_at': '2025-01-15T10:00:00Z',
              'assets': [
                {
                  'name': 'app-release.apk',
                  'browser_download_url': 'https://example.com/app-release.apk',
                },
              ],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');

      expect(update, isNotNull);
      expect(update!.latestVersion.toString(), '2.0.0');
      expect(update.apkUrl, 'https://example.com/app-release.apk');
      expect(update.changelogLines, contains('New feature'));
    });

    test('returns null when already up to date', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v1.0.0',
              'name': 'v1.0.0',
              'draft': false,
              'prerelease': false,
              'body': '- Initial release',
              'html_url': 'https://example.com',
              'assets': [],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('skips draft releases', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'draft': true,
              'prerelease': false,
              'body': '',
              'html_url': '',
              'assets': [],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('skips pre-releases', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v2.0.0-beta',
              'name': 'v2.0.0-beta',
              'draft': false,
              'prerelease': true,
              'body': '',
              'html_url': '',
              'assets': [],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('returns null on HTTP error', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response('error', 500);
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('returns null on network error', () async {
      final client = http_testing.MockClient((request) async {
        throw Exception('network error');
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update, isNull);
    });

    test('extracts APK URL from assets', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'draft': false,
              'prerelease': false,
              'body': '',
              'html_url': '',
              'assets': [
                {
                  'name': 'app-arm64-v8a-release.apk',
                  'browser_download_url': 'https://example.com/arm64.apk',
                },
                {
                  'name': 'app-armeabi-v7a-release.apk',
                  'browser_download_url': 'https://example.com/arm.apk',
                },
                {
                  'name': 'source.zip',
                  'browser_download_url': 'https://example.com/source.zip',
                },
              ],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update?.apkUrl, isNotNull);
    });

    test('parses changelog from release body', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'draft': false,
              'prerelease': false,
              'body':
                  '## What\'s New\n- Added feature A\n- Fixed bug B\n- Improved C',
              'html_url': '',
              'assets': [],
            },
          ]),
          200,
        );
      });

      final checker = UpdateChecker(client: client);
      final update = await checker.checkForUpdate('1.0.0');
      expect(update?.changelogLines, contains('Added feature A'));
      expect(update?.changelogLines, contains('Fixed bug B'));
    });
  });
}
