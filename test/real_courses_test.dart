import 'package:class_finder/models/course.dart';
import 'package:class_finder/services/real_courses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes official computer engineering major sections', () {
    final majorCourses = realCourses
        .where((course) => course.category.isMajor)
        .toList();

    expect(majorCourses, isNotEmpty);
    expect(
      majorCourses.map((course) => course.courseCode).toSet(),
      containsAll(<String>{
        '11024295',
        '11024725',
        '11024294',
        '11009499',
        '11024300',
        '11024302',
        '11024724',
        '11009473',
        '11024717',
        '11024299',
      }),
    );
  });

  test(
    'includes official computer engineering major electives without schedules',
    () {
      final unscheduledMajorElectives = realCourses
          .where(
            (course) =>
                course.category == CourseCategory.majorElective &&
                !course.hasTimeSlots,
          )
          .map((course) => course.name)
          .toSet();

      expect(
        unscheduledMajorElectives,
        containsAll(<String>{
          '자율형현장실습3',
          '자율형국외현장실습3',
          '표준형현장실습3',
          '표준형국외현장실습3',
        }),
      );
    },
  );

  test('includes official gajwa core liberal arts sections', () {
    final coreLiberalArts = realCourses
        .where((course) => course.category == CourseCategory.coreLiberalArts)
        .toList();

    expect(coreLiberalArts.length, greaterThan(200));
    expect(
      coreLiberalArts.map((course) => course.courseCode).toSet(),
      containsAll(<String>{
        'CWRIPROBLEM',
        'CENGREAD',
        'CENGGLOBAL',
        'CDIGAICODE',
        'CDIGPYTHON',
      }),
    );
  });
}
