import 'package:class_finder/services/department_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'department options include all departments extracted from the timetable',
    () {
      expect(departmentOptions, hasLength(110));
      expect(departmentOptions.toSet(), hasLength(departmentOptions.length));
      expect(departmentOptions, contains(defaultDepartment));
      expect(departmentOptions, contains('AI정보공학과'));
      expect(departmentOptions, contains('글로벌자율전공학부'));
      expect(departmentOptions, contains('융합전공'));
    },
  );

  test('normalizes unknown departments to the default department', () {
    expect(normalizeDepartment(''), defaultDepartment);
    expect(normalizeDepartment('없는학과'), defaultDepartment);
    expect(normalizeDepartment(' AI정보공학과 '), 'AI정보공학과');
  });
}
