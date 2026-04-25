import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/user_preference.dart';
import 'genetic_algorithm.dart';
import 'real_courses.dart';

List<Timetable> _gaIsolateEntry(_GAPayload payload) {
  return GeneticAlgorithmService().run(payload.courses, payload.preference);
}

class _GAPayload {
  final List<Course> courses;
  final UserPreference preference;

  const _GAPayload(this.courses, this.preference);
}

class AppState extends ChangeNotifier {
  UserPreference _preference = const UserPreference(major: '컴퓨터공학과', grade: 2);
  List<Timetable> _results = [];
  bool _isLoading = false;
  int _selectedResultIndex = 0;
  Duration? _estimatedMatchingDuration;
  Duration? _lastMatchingDuration;
  final Map<String, double> _timingHistoryMs = {};

  UserPreference get pref => _preference;
  List<Timetable> get results => _results;
  bool get isLoading => _isLoading;
  int get selectedResultIndex => _selectedResultIndex;
  Duration? get estimatedMatchingDuration => _estimatedMatchingDuration;
  Duration? get lastMatchingDuration => _lastMatchingDuration;
  Timetable? get selectedTimetable =>
      _results.isEmpty ? null : _results[_selectedResultIndex];

  void updatePref(UserPreference preference) {
    _preference = preference;
    notifyListeners();
  }

  void toggleRequiredCourse(String courseId) {
    final ids = List<String>.from(_preference.requiredCourseIds);
    if (ids.contains(courseId)) {
      ids.remove(courseId);
    } else {
      ids.add(courseId);
    }

    _preference = _preference.copyWith(requiredCourseIds: ids);
    notifyListeners();
  }

  void selectResult(int index) {
    _selectedResultIndex = index;
    notifyListeners();
  }

  Future<void> runMatching() async {
    _estimatedMatchingDuration = _estimateMatchingDuration(
      realCourses,
      _preference,
    );
    _isLoading = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    _results = await compute(
      _gaIsolateEntry,
      _GAPayload(realCourses, _preference),
    );
    stopwatch.stop();
    _recordMatchingDuration(realCourses, _preference, stopwatch.elapsed);

    _selectedResultIndex = 0;
    _isLoading = false;
    notifyListeners();
  }

  Duration _estimateMatchingDuration(
    List<Course> courses,
    UserPreference preference,
  ) {
    final eligibleCount = courses
        .where(
          (course) => course.grade == 0 || course.grade <= preference.grade,
        )
        .length;
    final requiredCount = preference.requiredCourseIds.length;
    final heuristicMs =
        72 +
        eligibleCount * 1.35 +
        preference.maxCredits * 1.7 +
        requiredCount * 7 +
        preference.preferredFreeDays.length * 10 +
        (preference.requireLunchBreak ? 14 : 0) +
        (preference.preferMorning ? 10 : 0);
    final bucket = _timingBucket(eligibleCount, preference);
    final historyMs = _timingHistoryMs[bucket];
    final estimatedMs = historyMs == null
        ? heuristicMs
        : historyMs * 0.72 + heuristicMs * 0.28;

    return Duration(milliseconds: estimatedMs.round().clamp(90, 3000));
  }

  void _recordMatchingDuration(
    List<Course> courses,
    UserPreference preference,
    Duration duration,
  ) {
    final eligibleCount = courses
        .where(
          (course) => course.grade == 0 || course.grade <= preference.grade,
        )
        .length;
    final bucket = _timingBucket(eligibleCount, preference);
    final currentMs = duration.inMilliseconds.toDouble();
    final previousMs = _timingHistoryMs[bucket];

    _timingHistoryMs[bucket] = previousMs == null
        ? currentMs
        : previousMs * 0.65 + currentMs * 0.35;
    _lastMatchingDuration = duration;
    _estimatedMatchingDuration = Duration(
      milliseconds: _timingHistoryMs[bucket]!.round().clamp(90, 3000),
    );
  }

  String _timingBucket(int eligibleCount, UserPreference preference) {
    return [
      preference.grade,
      eligibleCount ~/ 12,
      preference.maxCredits ~/ 3,
      preference.requiredCourseIds.length ~/ 2,
      preference.preferredFreeDays.length,
      preference.preferMorning ? 1 : 0,
      preference.requireLunchBreak ? 1 : 0,
    ].join('|');
  }
}
