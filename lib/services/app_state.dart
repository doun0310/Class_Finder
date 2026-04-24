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

  UserPreference get pref => _preference;
  List<Timetable> get results => _results;
  bool get isLoading => _isLoading;
  int get selectedResultIndex => _selectedResultIndex;
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
    _isLoading = true;
    notifyListeners();

    _results = await compute(
      _gaIsolateEntry,
      _GAPayload(realCourses, _preference),
    );

    _selectedResultIndex = 0;
    _isLoading = false;
    notifyListeners();
  }
}
