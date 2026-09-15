import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/moodboard.dart';
import '../models/wallpaper.dart';

class HiveMoodboardService {
  static const String _boxName = 'moodboards';
  static Box get _box => Hive.box(_boxName);

  static final ValueNotifier<int> moodboardNotifier = ValueNotifier<int>(0);

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  static List<Map<String, dynamic>> _getRaw(String userId) {
    final raw = _box.get(userId);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static List<Map<String, dynamic>> getRawMoodboards(String userId) {
    return _getRaw(userId);
  }

  static Future<List<Moodboard>> getMoodboards(String userId) async {
    return _getRaw(userId).map((m) => Moodboard.fromMap(m)).toList();
  }

  static Future<Moodboard?> getMoodboard(String moodboardId) async {
    for (final userId in _box.keys) {
      final boards = await getMoodboards(userId.toString());
      for (final board in boards) {
        if (board.id == moodboardId) return board;
      }
    }
    return null;
  }

  static Future<Moodboard?> createMoodboard(String userId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final boards = _getRaw(userId);
    final newBoard = {
      'id': _generateId(),
      'name': trimmed,
      'wallpapers': <Map<String, dynamic>>[],
      'created_at': DateTime.now().toIso8601String(),
    };
    boards.add(newBoard);
    await _box.put(userId, boards);
    moodboardNotifier.value++;
    return Moodboard.fromMap(newBoard);
  }

  static Future<bool> deleteMoodboard(String userId, String moodboardId) async {
    final boards = _getRaw(userId);
    final originalLength = boards.length;
    boards.removeWhere((b) => b['id'] == moodboardId);
    if (boards.length == originalLength) return false;
    await _box.put(userId, boards);
    moodboardNotifier.value++;
    return true;
  }

  static Future<List<Wallpaper>> getWallpapers(String moodboardId) async {
    for (final userId in _box.keys) {
      final boards = _getRaw(userId.toString());
      for (final board in boards) {
        if (board['id'] == moodboardId) {
          final raw = board['wallpapers'] as List? ?? [];
          return raw
              .map(
                (e) => Wallpaper.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      }
    }
    return [];
  }

  static Future<bool> containsWallpaper(
    String moodboardId,
    String wallhavenId,
  ) async {
    final wps = await getWallpapers(moodboardId);
    return wps.any((w) => w.wallhavenId == wallhavenId);
  }

  static Future<bool> addWallpaper(
    String moodboardId,
    Wallpaper wallpaper,
  ) async {
    for (final userId in _box.keys) {
      final boards = _getRaw(userId.toString());
      for (final board in boards) {
        if (board['id'] == moodboardId) {
          final wallpapers = (board['wallpapers'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (wallpapers.any(
            (w) => w['wallhaven_id'] == wallpaper.wallhavenId,
          )) {
            return false;
          }
          wallpapers.add(wallpaper.toMap());
          board['wallpapers'] = wallpapers;
          await _box.put(userId.toString(), boards);
          moodboardNotifier.value++;
          return true;
        }
      }
    }
    return false;
  }

  static Future<bool> removeWallpaper(
    String moodboardId,
    String wallhavenId,
  ) async {
    for (final userId in _box.keys) {
      final boards = _getRaw(userId.toString());
      for (final board in boards) {
        if (board['id'] == moodboardId) {
          final wallpapers = (board['wallpapers'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final original = wallpapers.length;
          wallpapers.removeWhere((w) => w['wallhaven_id'] == wallhavenId);
          if (wallpapers.length == original) return false;
          board['wallpapers'] = wallpapers;
          await _box.put(userId.toString(), boards);
          moodboardNotifier.value++;
          return true;
        }
      }
    }
    return false;
  }

  static Future<List<Moodboard>> getMoodboardsForWallpaper(
    String userId,
    String wallhavenId,
  ) async {
    final boards = await getMoodboards(userId);
    final result = <Moodboard>[];
    for (final board in boards) {
      final wps = await getWallpapers(board.id);
      if (wps.any((w) => w.wallhavenId == wallhavenId)) {
        result.add(board);
      }
    }
    return result;
  }

  static Future<void> setAll(
    String userId,
    List<Map<String, dynamic>> moodboards,
  ) async {
    await _box.put(userId, moodboards);
  }
}
