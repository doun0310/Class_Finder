import 'package:class_finder/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Course.fromJson defaults rating source to official estimate', () {
    final course = Course.fromJson({
      'id': 'TEST-001',
      'name': 'Test course',
      'professor': 'Professor',
      'credit': 3,
      'rating': 4.1,
      'difficulty': 2,
      'hasTeamProject': false,
      'isMajorRequired': false,
      'category': 'majorElective',
      'grade': 2,
      'timeSlots': [
        {'day': '월', 'startHour': 9, 'endHour': 11},
      ],
    });

    expect(course.ratingSource, RatingSource.officialEstimate);
    expect(course.toJson()['ratingSource'], 'officialEstimate');
  });

  test('Course.toJson preserves explicit rating source', () {
    const course = Course(
      id: 'TEST-002',
      name: 'Review backed course',
      professor: 'Reviewer',
      credit: 2,
      rating: 4.5,
      ratingSource: RatingSource.reviewBacked,
      difficulty: 1,
      hasTeamProject: false,
      isMajorRequired: false,
      category: CourseCategory.coreLiberalArts,
      grade: 0,
      timeSlots: [],
    );

    expect(course.toJson()['ratingSource'], 'reviewBacked');
  });

  test('Course.toJson preserves balanced liberal arts category', () {
    const course = Course(
      id: 'TEST-003',
      name: 'Balanced course',
      professor: 'Tester',
      credit: 2,
      rating: 4.0,
      difficulty: 2,
      hasTeamProject: false,
      isMajorRequired: false,
      category: CourseCategory.balancedLiberalArts,
      grade: 0,
      timeSlots: [],
    );

    expect(course.category, CourseCategory.balancedLiberalArts);
    expect(course.categoryLabel, '균형교양');
    expect(course.toJson()['category'], 'balancedLiberalArts');
  });
}
