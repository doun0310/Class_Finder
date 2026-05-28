import 'package:class_finder/screens/course_search_screen.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('course search shows added unscheduled lectures with ratings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const CourseSearchScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('강의 탐색'), findsOneWidget);
    expect(find.text('평점 근거'), findsOneWidget);
    expect(find.text('공식 추정'), findsWidgets);
    expect(find.text('사용자 입력'), findsOneWidget);
    expect(find.text('실제 리뷰 반영'), findsOneWidget);

    final unscheduledChip = find.widgetWithText(ChoiceChip, '시간표 미지정');
    await tester.ensureVisible(unscheduledChip);
    await tester.pumpAndSettle();
    await tester.tap(unscheduledChip);
    await tester.pumpAndSettle();

    expect(find.text('자율형현장실습3'), findsOneWidget);
    expect(find.text('자율형국외현장실습3'), findsOneWidget);
    expect(find.text('과목코드 CEFIELDSELF3'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });
}
