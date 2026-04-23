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

  int get totalCredits => courses.fold(0, (s, c) => s + c.credit);

  int get freeDays {
    const days = ['월', '화', '수', '목', '금'];
    return days
        .where((d) => courses.every((c) => c.timeSlots.every((s) => s.day != d)))
        .length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'courses': courses.map((c) => c.toJson()).toList(),
        'score': score,
        'scoreBreakdown': scoreBreakdown,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedTimetable.fromJson(Map<String, dynamic> j) => SavedTimetable(
        id: j['id'] as String,
        userId: j['userId'] as String,
        name: j['name'] as String,
        courses: (j['courses'] as List)
            .map((c) => Course.fromJson(c as Map<String, dynamic>))
            .toList(),
        score: (j['score'] as num).toDouble(),
        scoreBreakdown: Map<String, double>.from(
            (j['scoreBreakdown'] as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toDouble()))),
        savedAt: DateTime.parse(j['savedAt'] as String),
      );
}
