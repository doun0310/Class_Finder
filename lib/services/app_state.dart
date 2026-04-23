import 'package:flutter/foundation.dart';
import '../models/user_preference.dart';
import '../services/genetic_algorithm.dart';
import '../services/real_courses.dart';

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
    if (ids.contains(courseId)) {
      ids.remove(courseId);
    } else {
      ids.add(courseId);
    }
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
    await Future.delayed(const Duration(milliseconds: 100));
    _results = GeneticAlgorithmService().run(realCourses, _pref);
    _selectedResultIndex = 0;
    _isLoading = false;
    notifyListeners();
  }
}
