import 'package:class_finder/services/department_options.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:class_finder/widgets/department_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('department picker opens a compact searchable sheet', (
    tester,
  ) async {
    var selected = defaultDepartment;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: DepartmentPickerField(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text(defaultDepartment), findsOneWidget);
    expect(find.text('AI정보공학과'), findsNothing);

    await tester.tap(find.text(defaultDepartment));
    await tester.pumpAndSettle();

    expect(find.text('학과 선택'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'AI');
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI정보공학과'));
    await tester.pumpAndSettle();

    expect(selected, 'AI정보공학과');
  });
}
