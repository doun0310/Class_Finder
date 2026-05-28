import 'package:class_finder/services/genetic_algorithm.dart';
import 'package:class_finder/services/real_courses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('timetable summary values are computed consistently', () {
    final courses = realCourses
        .where(
          (course) =>
              course.id == '11024295-001' || course.id == '11024725-001',
        )
        .toList(growable: false);

    final timetable = Timetable(courses: courses, score: 0.82);

    expect(timetable.totalCredits, 6);
    expect(timetable.totalHours, 6);
    expect(timetable.averageRating, closeTo(3.65, 0.001));
    expect(timetable.freeDays, 3);
    expect(timetable.activeDayCount, 2);
    expect(timetable.earliestStartHour, 9);
    expect(timetable.latestEndHour, 16);
    expect(timetable.averageGapHours, 0);
    expect(timetable.consecutiveMax, 3);
  });
}
