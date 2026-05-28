import 'dart:math';

import 'package:class_finder/models/user_preference.dart';
import 'package:class_finder/services/genetic_algorithm.dart';
import 'package:class_finder/services/real_courses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes only the selected grade major required courses', () {
    final secondGradePreference = const UserPreference(
      major: '컴퓨터공학부',
      grade: 2,
      maxCredits: 18,
    );
    final fourthGradePreference = const UserPreference(
      major: '컴퓨터공학부',
      grade: 4,
      maxCredits: 18,
    );

    final secondGradeResults = GeneticAlgorithmService(
      random: Random(0),
    ).run(realCourses, secondGradePreference);
    final fourthGradeResults = GeneticAlgorithmService(
      random: Random(0),
    ).run(realCourses, fourthGradePreference);

    expect(secondGradeResults, isNotEmpty);
    expect(fourthGradeResults, isNotEmpty);

    expect(
      secondGradeResults.every((timetable) {
        final courseCodes = timetable.courses
            .map((course) => course.courseCode)
            .toSet();
        return courseCodes.contains('11024294') &&
            !courseCodes.contains('11024295') &&
            !courseCodes.contains('11024299');
      }),
      isTrue,
    );

    expect(
      fourthGradeResults.every((timetable) {
        final courseCodes = timetable.courses
            .map((course) => course.courseCode)
            .toSet();
        return courseCodes.contains('11024299') &&
            !courseCodes.contains('11024295') &&
            !courseCodes.contains('11024294');
      }),
      isTrue,
    );
  });

  test(
    'keeps selected major and liberal arts sections fixed in the results',
    () {
      final preference = const UserPreference(
        major: '컴퓨터공학부',
        grade: 4,
        maxCredits: 18,
        selectedMajorCourseIds: ['11024724-003'],
        selectedLiberalArtsCourseIds: ['CWRIPROBLEM-021'],
      );

      final results = GeneticAlgorithmService(
        random: Random(0),
      ).run(realCourses, preference);

      expect(results, isNotEmpty);
      expect(
        results.every(
          (timetable) => timetable.courses
              .map((course) => course.id)
              .toSet()
              .containsAll(<String>{'11024724-003', 'CWRIPROBLEM-021'}),
        ),
        isTrue,
      );
    },
  );
}
