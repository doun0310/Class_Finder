import 'package:flutter/foundation.dart';
import '../models/user_preference.dart';
import '../models/course.dart';
import '../services/genetic_algorithm.dart';
import '../services/real_courses.dart';

// compute()는 최상위 함수만 허용 → 클래스 밖에 선언
List<Timetable> _gaIsolateEntry(_GAPayload payload) {
  return GeneticAlgorithmService().run(payload.courses, payload.pref);
}

class _GAPayload {
  final List<Course> courses;
  final UserPreference pref;
  const _GAPayload(this.courses, this.pref);
}

class AppState extends ChangeNotifier {
  UserPreference _pref = const UserPreference(major: '컴퓨터공학', grade: 2);
  List<Timetable> _results = [];
  bool _isLoading = false;
  int _selectedResultIndex = 0;

  UserPreference get pref => _pref;
  List<Timetable> get results => _results;
  bool get isLoading => _isLoading;
  int get selectedResultIndex => _selectedResultIndex;
  Timetable? get selectedTimetable =>
      _results.isEmpty ? null : _results[_selectedResultIndex];

  void updatePref(UserPreference pref) {
    _pref = pref;
    notifyListeners();
  }

  void toggleRequiredCourse(String courseId) {
    final ids = List<String>.from(_pref.requiredCourseIds);
    ids.contains(courseId) ? ids.remove(courseId) : ids.add(courseId);
    _pref = _pref.copyWith(requiredCourseIds: ids);
    notifyListeners();
  }

  void selectResult(int index) {
    _selectedResultIndex = index;
    notifyListeners();
  }

  Future<void> runMatching() async {
    _isLoading = true;
    notifyListeners();
    // compute()로 별도 isolate 실행 → UI 블로킹 방지
    _results = await compute(
      _gaIsolateEntry,
      _GAPayload(realCourses, _pref),
    );
    _selectedResultIndex = 0;
    _isLoading = false;
    notifyListeners();
  }
}
