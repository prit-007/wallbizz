import 'dart:convert';
import 'package:http/http.dart' as http;

class AppVersion {
  final int major;
  final int minor;
  final int patch;

  AppVersion(this.major, this.minor, this.patch);

  factory AppVersion.parse(String version) {
    final cleaned = version.split('+').first.split('-').first;
    final parts = cleaned.split('.');
    return AppVersion(
      int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
    );
  }

  bool isNewerThan(AppVersion other) {
    if (major > other.major) return true;
    if (major == other.major && minor > other.minor) return true;
    if (major == other.major && minor == other.minor && patch > other.patch) {
      return true;
    }
    return false;
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class UpdateInfo {
  final AppVersion latestVersion;
  final String releaseName;
  final String releaseBody;
  final String releaseUrl;
  final String? publishedAt;
  final String? apkUrl;
  final List<String> changelogLines;

  UpdateInfo({
    required this.latestVersion,
    required this.releaseName,
    required this.releaseBody,
    required this.releaseUrl,
    this.publishedAt,
    this.apkUrl,
    this.changelogLines = const [],
  });
}

class UpdateChecker {
  static const _repoOwner = 'prit-007';
  static const _repoName = 'wallbizz';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases';

  final http.Client _client;

  UpdateChecker({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final response = await _client
          .get(Uri.parse('$_apiUrl?per_page=10'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final releases = json.decode(response.body) as List<dynamic>;
      final current = AppVersion.parse(currentVersion);

      for (final release in releases) {
        if (release['draft'] == true || release['prerelease'] == true) continue;

        final tagName = release['tag_name'] as String? ?? '';
        final versionStr = tagName.replaceFirst('v', '');
        final latest = AppVersion.parse(versionStr);

        if (latest.isNewerThan(current)) {
          final body = release['body'] as String? ?? '';
          final apkUrl = _extractApkUrl(release['assets'] as List<dynamic>?);

          return UpdateInfo(
            latestVersion: latest,
            releaseName: release['name'] as String? ?? tagName,
            releaseBody: body,
            releaseUrl: release['html_url'] as String? ?? '',
            publishedAt: release['published_at'] as String?,
            apkUrl: apkUrl,
            changelogLines: _parseChangelog(body),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractApkUrl(List<dynamic>? assets) {
    if (assets == null) return null;
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk') && !name.contains('unsigned')) {
        return asset['browser_download_url'] as String?;
      }
    }
    return null;
  }

  List<String> _parseChangelog(String body) {
    final lines = body.split('\n');
    final changelog = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        changelog.add(trimmed.substring(2));
      } else if (trimmed.startsWith('## ')) {
        changelog.add(trimmed.substring(3));
      }
    }
    return changelog.take(10).toList();
  }
}
