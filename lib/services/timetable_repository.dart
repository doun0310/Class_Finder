import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_timetable.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'genetic_algorithm.dart';

abstract class TimetableRepository {
  const TimetableRepository();

  Future<List<SavedTimetable>> listByUser(User user);

  Future<SavedTimetable> save({
    required User user,
    required String name,
    required Timetable timetable,
  });

  Future<void> delete({required User user, required String id});

  Future<void> rename({
    required User user,
    required String id,
    required String newName,
  });

  void dispose() {}

  static Timetable toTimetable(SavedTimetable saved) => Timetable(
    courses: saved.courses,
    score: saved.score,
    scoreBreakdown: saved.scoreBreakdown,
  );
}

class LocalTimetableRepository extends TimetableRepository {
  static const _key = 'timetables.saved';

  const LocalTimetableRepository();

  @override
  Future<List<SavedTimetable>> listByUser(User user) async {
    final all = await _readAll();
    final list = all.where((t) => t.userId == user.id).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  @override
  Future<SavedTimetable> save({
    required User user,
    required String name,
    required Timetable timetable,
  }) async {
    final saved = SavedTimetable(
      id: _randomId(),
      userId: user.id,
      name: _normalizeName(name),
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

  @override
  Future<void> delete({required User user, required String id}) async {
    final all = await _readAll();
    all.removeWhere((t) => t.id == id && t.userId == user.id);
    await _writeAll(all);
  }

  @override
  Future<void> rename({
    required User user,
    required String id,
    required String newName,
  }) async {
    final all = await _readAll();
    final idx = all.indexWhere((t) => t.id == id && t.userId == user.id);
    if (idx == -1) {
      return;
    }
    final old = all[idx];
    all[idx] = SavedTimetable(
      id: old.id,
      userId: old.userId,
      name: _normalizeName(newName),
      courses: old.courses,
      score: old.score,
      scoreBreakdown: old.scoreBreakdown,
      savedAt: old.savedAt,
    );
    await _writeAll(all);
  }

  Future<List<SavedTimetable>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (entry) => SavedTimetable.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<SavedTimetable> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  static String _randomId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(12, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _normalizeName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Saved Timetable' : trimmed;
  }
}

class RemoteTimetableRepository extends TimetableRepository {
  static const _tokenKey = 'auth.token';

  final ApiClient client;

  const RemoteTimetableRepository({required this.client});

  @override
  Future<List<SavedTimetable>> listByUser(User user) async {
    try {
      await _restoreToken();
      final response = await client.get('/users/${user.id}/timetables');
      final rows = response['timetables'] as List? ?? const [];
      return rows
          .map(
            (entry) => SavedTimetable.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();
    } on ApiException catch (error) {
      throw TimetableRepositoryException(error.message);
    } catch (_) {
      throw const TimetableRepositoryException('저장된 시간표를 불러오지 못했습니다.');
    }
  }

  @override
  Future<SavedTimetable> save({
    required User user,
    required String name,
    required Timetable timetable,
  }) async {
    try {
      await _restoreToken();
      final response = await client.post('/users/${user.id}/timetables', {
        'name': name,
        'score': timetable.score,
        'scoreBreakdown': timetable.scoreBreakdown,
        'courses': timetable.courses.map((course) => course.toJson()).toList(),
      });
      return SavedTimetable.fromJson(
        Map<String, dynamic>.from(response['timetable'] as Map),
      );
    } on ApiException catch (error) {
      throw TimetableRepositoryException(error.message);
    } catch (_) {
      throw const TimetableRepositoryException('시간표를 서버에 저장하지 못했습니다.');
    }
  }

  @override
  Future<void> delete({required User user, required String id}) async {
    try {
      await _restoreToken();
      await client.delete('/users/${user.id}/timetables/$id');
    } on ApiException catch (error) {
      throw TimetableRepositoryException(error.message);
    } catch (_) {
      throw const TimetableRepositoryException('시간표를 삭제하지 못했습니다.');
    }
  }

  @override
  Future<void> rename({
    required User user,
    required String id,
    required String newName,
  }) async {
    try {
      await _restoreToken();
      await client.patch('/users/${user.id}/timetables/$id', {'name': newName});
    } on ApiException catch (error) {
      throw TimetableRepositoryException(error.message);
    } catch (_) {
      throw const TimetableRepositoryException('시간표 이름을 변경하지 못했습니다.');
    }
  }

  @override
  void dispose() {
    client.dispose();
  }

  Future<void> _restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    client.setToken(prefs.getString(_tokenKey));
  }
}

class TimetableRepositoryException implements Exception {
  final String message;

  const TimetableRepositoryException(this.message);

  @override
  String toString() => message;
}
