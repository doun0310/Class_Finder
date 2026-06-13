import 'dart:math';

import 'package:class_finder/models/course.dart';
import 'package:class_finder/models/user_preference.dart';
import 'package:class_finder/services/genetic_algorithm.dart';
import 'package:class_finder/services/real_courses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses only the selected grade major courses in recommendations', () {
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
      secondGradeResults.every(
        (timetable) => timetable.courses
            .where((course) => course.category.isMajor)
            .every((course) => course.grade == 0 || course.grade == 2),
      ),
      isTrue,
    );
    expect(
      fourthGradeResults.every(
        (timetable) => timetable.courses
            .where((course) => course.category.isMajor)
            .every((course) => course.grade == 0 || course.grade == 4),
      ),
      isTrue,
    );
  });

  test('keeps selected same-grade major and liberal arts sections fixed', () {
    final preference = const UserPreference(
      major: '컴퓨터공학부',
      grade: 4,
      maxCredits: 18,
      selectedMajorCourseIds: ['11024716-001'],
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
            .containsAll(<String>{'11024716-001', 'CWRIPROBLEM-021'}),
      ),
      isTrue,
    );
  });

  test('first-year recommendations stay core-liberal-arts heavy', () {
    final results = GeneticAlgorithmService(random: Random(1)).run(
      realCourses,
      const UserPreference(major: '컴퓨터공학부', grade: 1, maxCredits: 18),
    );

    expect(results, isNotEmpty);

    final top = results.first.courses;
    final coreCount = top
        .where((course) => course.category == CourseCategory.coreLiberalArts)
        .length;
    final balancedCount = top
        .where(
          (course) => course.category == CourseCategory.balancedLiberalArts,
        )
        .length;

    expect(coreCount, greaterThanOrEqualTo(1));
    expect(coreCount, greaterThanOrEqualTo(balancedCount));
  });

  test('upper-grade recommendations keep liberal arts light', () {
    final results = GeneticAlgorithmService(random: Random(2)).run(
      realCourses,
      const UserPreference(major: '컴퓨터공학부', grade: 4, maxCredits: 18),
    );

    expect(results, isNotEmpty);

    final top = results.first.courses;
    final liberalArtsCount = top
        .where((course) => !course.category.isMajor)
        .length;
    final balancedCount = top
        .where(
          (course) => course.category == CourseCategory.balancedLiberalArts,
        )
        .length;
    final coreCount = top
        .where((course) => course.category == CourseCategory.coreLiberalArts)
        .length;

    expect(liberalArtsCount, lessThanOrEqualTo(2));
    expect(balancedCount, lessThanOrEqualTo(2));
    expect(coreCount, lessThanOrEqualTo(1));
  });

  test('keeps selected free days completely empty', () {
    final results = GeneticAlgorithmService(random: Random(3)).run(
      realCourses,
      const UserPreference(
        major: '컴퓨터공학부',
        grade: 4,
        maxCredits: 18,
        preferredFreeDays: ['금'],
      ),
    );

    expect(results, isNotEmpty);
    expect(
      results.every(
        (timetable) =>
            timetable.courses.every((course) => !course.occursOn('금')),
      ),
      isTrue,
    );
  });

  test('top alternatives keep comparison diversity', () {
    final results = GeneticAlgorithmService(random: Random(4)).run(
      realCourses,
      const UserPreference(
        major: '컴퓨터공학부',
        grade: 3,
        maxCredits: 18,
        preferredFreeDays: ['금'],
      ),
    );

    expect(results.length, greaterThanOrEqualTo(3));

    final signatures = results.map(_alternativeSignature).toSet();
    expect(signatures.length, greaterThanOrEqualTo(min(3, results.length)));
  });
}

String _alternativeSignature(Timetable timetable) {
  final activeDays = weekdays
      .where((day) => timetable.courses.any((course) => course.occursOn(day)))
      .join(',');
  final courseCodes =
      timetable.courses.map((course) => course.courseCode).toList()..sort();
  return '$activeDays|${courseCodes.join(',')}';
}
