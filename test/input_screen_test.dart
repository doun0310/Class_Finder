import 'package:class_finder/screens/input_screen.dart';
import 'package:class_finder/services/app_state.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildHarness(Widget child, WidgetTester tester) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: const TextScaler.linear(1.1)),
          child: child,
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('input screen separates major and liberal arts selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildHarness(const InputScreen(), tester));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('자동 반영 전공필수'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('자동 반영 전공필수'), findsOneWidget);
    expect(find.text('전공 선택'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('교양 선택'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('교양 선택'), findsOneWidget);
    expect(find.text('전공필수 분반 선택'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
