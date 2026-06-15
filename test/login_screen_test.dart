import 'package:class_finder/screens/auth/login_screen.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:class_finder/services/runtime_config.dart';
import 'package:class_finder/services/social_auth_service.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildHarness({required RuntimeConfig runtimeConfig}) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => runtimeConfig),
        ChangeNotifierProvider(
          create: (_) => AuthService(
            LocalAuthRepository(),
            socialAuth: _FakeSocialAuthService(),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    );
  }

  testWidgets('login screen shows branded social logos', (tester) async {
    await tester.pumpWidget(
      buildHarness(runtimeConfig: const RuntimeConfig(apiBaseUrl: '')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('social-logo-google')), findsOneWidget);
    expect(find.byKey(const ValueKey('social-logo-kakao')), findsOneWidget);
    expect(find.byKey(const ValueKey('social-logo-apple')), findsOneWidget);
    expect(find.text('Talk'), findsNothing);
  });

  testWidgets('login screen shows local storage mode notice', (tester) async {
    await tester.pumpWidget(
      buildHarness(runtimeConfig: const RuntimeConfig(apiBaseUrl: '')),
    );
    await tester.pumpAndSettle();

    expect(find.text('로컬 저장 모드'), findsOneWidget);
    expect(find.textContaining('이 기기 안에만 저장'), findsOneWidget);
  });

  testWidgets('login screen shows backend storage mode notice', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        runtimeConfig: const RuntimeConfig(apiBaseUrl: 'http://localhost:3001'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('서버 저장 모드'), findsOneWidget);
    expect(find.textContaining('서버에 저장됩니다'), findsOneWidget);
  });
}

class _FakeSocialAuthService implements SocialAuthGateway {
  @override
  Future<SocialAuthPayload> authenticate(AuthProvider provider) async {
    return SocialAuthPayload(provider: provider);
  }
}
