import 'package:class_finder/screens/auth/login_screen.dart';
import 'package:class_finder/screens/auth/signup_screen.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildAuthHarness(Widget child, WidgetTester tester) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(LocalAuthRepository()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: const TextScaler.linear(1.2)),
          child: child,
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login screen does not overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildAuthHarness(const LoginScreen(), tester));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('signup screen does not overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildAuthHarness(const SignupScreen(), tester));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('password reset sheet does not overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildAuthHarness(const Scaffold(body: PasswordResetSheet()), tester),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
