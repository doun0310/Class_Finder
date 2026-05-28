import 'package:class_finder/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Course.fromJson defaults rating source to official estimate', () {
    final course = Course.fromJson({
      'id': 'TEST-001',
      'name': '테스트 과목',
      'professor': '홍길동',
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
    expect(course.ratingSourceLabel, '공식 추정');
  });

  test('Course.toJson preserves explicit rating source', () {
    const course = Course(
      id: 'TEST-002',
      name: '리뷰 반영 과목',
      professor: '이몽룡',
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
}
