import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_timetable.dart';
import 'genetic_algorithm.dart';

/// 사용자별 저장된 시간표 관리 (로컬 구현)
/// 실서버 연동 시 RemoteTimetableRepository로 swap 가능
class TimetableRepository {
  static const _key = 'timetables.saved';

  Future<List<SavedTimetable>> listByUser(String userId) async {
    final all = await _readAll();
    final list = all.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  Future<SavedTimetable> save({
    required String userId,
    required String name,
    required Timetable timetable,
  }) async {
    final saved = SavedTimetable(
      id: _randomId(),
      userId: userId,
      name: name.trim().isEmpty ? '무제 시간표' : name.trim(),
      courses: timetable.courses,
      score: timetable.score,
      scoreBreakdown: timetable.scoreBreakdown,
      savedAt: DateTime.now(),
    );
    final all = await _readAll();
    all.add(saved);
    await _writeAll(all);
    return saved;
  }

  Future<void> delete(String id) async {
    final all = await _readAll();
    all.removeWhere((t) => t.id == id);
    await _writeAll(all);
  }

  Future<void> rename(String id, String newName) async {
    final all = await _readAll();
    final idx = all.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final old = all[idx];
    all[idx] = SavedTimetable(
      id: old.id,
      userId: old.userId,
      name: newName.trim().isEmpty ? '무제 시간표' : newName.trim(),
      courses: old.courses,
      score: old.score,
      scoreBreakdown: old.scoreBreakdown,
      savedAt: old.savedAt,
    );
    await _writeAll(all);
  }

  /// SavedTimetable → Timetable 변환 (시간표 그리드에 사용)
  static Timetable toTimetable(SavedTimetable saved) => Timetable(
        courses: saved.courses,
        score: saved.score,
        scoreBreakdown: saved.scoreBreakdown,
      );

  // ── 내부 ──────────────────────────────────────────────────────
  Future<List<SavedTimetable>> _readAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              SavedTimetable.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<SavedTimetable> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.map((t) => t.toJson()).toList()));
  }

  static String _randomId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(12, (_) => rng.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

