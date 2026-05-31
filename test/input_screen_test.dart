import 'package:class_finder/screens/input_screen.dart';
import 'package:class_finder/models/user.dart';
import 'package:class_finder/services/app_state.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:class_finder/services/social_auth_service.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildHarness(
    Widget child,
    WidgetTester tester, {
    required AuthService authService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
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

  Future<void> pumpInputScreen(
    WidgetTester tester, {
    required AuthService authService,
  }) async {
    await tester.pumpWidget(
      buildHarness(const InputScreen(), tester, authService: authService),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('input screen separates major and liberal arts selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final authService = AuthService(
      LocalAuthRepository(),
      socialAuth: _FakeSocialAuthService(),
    );

    await pumpInputScreen(tester, authService: authService);

    await tester.scrollUntilVisible(
      find.text('자동 반영 전공필수'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('자동 반영 전공필수'), findsOneWidget);
    expect(find.text('전공 선택'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('교양 선택'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('교양 선택'), findsOneWidget);
    expect(find.text('전공필수 분반 선택'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('input screen prioritizes logged-in user grade', (tester) async {
    SharedPreferences.setMockInitialValues({'grade': 2, 'auth.token': 'token'});

    final authService = AuthService(
      _SeededAuthRepository(
        user: User(
          id: 'user-4',
          email: 'senior@example.com',
          name: '시니어',
          studentId: '20201234',
          department: '컴퓨터공학부',
          grade: 4,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      socialAuth: _FakeSocialAuthService(),
    );
    await authService.loadSession();

    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpInputScreen(tester, authService: authService);

    expect(find.text('4학년 기준'), findsOneWidget);
    expect(find.text('2학년 기준'), findsNothing);
  });
}

class _FakeSocialAuthService implements SocialAuthGateway {
  @override
  Future<SocialAuthPayload> authenticate(AuthProvider provider) async {
    return SocialAuthPayload(provider: provider);
  }
}

class _SeededAuthRepository implements AuthRepository {
  final User user;

  const _SeededAuthRepository({required this.user});

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<String> requestPasswordReset({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<User> updateProfile(User user) async => user;
}
