import 'course.dart';

class SavedTimetable {
  final String id;
  final String userId;
  final String name;
  final List<Course> courses;
  final double score;
  final Map<String, double> scoreBreakdown;
  final DateTime savedAt;

  const SavedTimetable({
    required this.id,
    required this.userId,
    required this.name,
    required this.courses,
    required this.score,
    required this.scoreBreakdown,
    required this.savedAt,
  });

  int get totalCredits => courses.fold(0, (sum, course) => sum + course.credit);

  int get freeDays => weekdays
      .where((day) => courses.every((course) => !course.occursOn(day)))
      .length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'courses': courses.map((course) => course.toJson()).toList(),
    'score': score,
    'scoreBreakdown': scoreBreakdown,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedTimetable.fromJson(Map<String, dynamic> json) => SavedTimetable(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    courses: (json['courses'] as List)
        .map((course) => Course.fromJson(course as Map<String, dynamic>))
        .toList(),
    score: (json['score'] as num).toDouble(),
    scoreBreakdown: Map<String, double>.from(
      (json['scoreBreakdown'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    ),
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}
