import 'package:class_finder/screens/auth/login_screen.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:class_finder/services/social_auth_service.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('login screen shows branded social logos', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(
          LocalAuthRepository(),
          socialAuth: _FakeSocialAuthService(),
        ),
        child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('social-logo-google')), findsOneWidget);
    expect(find.byKey(const ValueKey('social-logo-kakao')), findsOneWidget);
    expect(find.byKey(const ValueKey('social-logo-apple')), findsOneWidget);
  });
}

class _FakeSocialAuthService implements SocialAuthGateway {
  @override
  Future<SocialAuthPayload> authenticate(AuthProvider provider) async {
    return SocialAuthPayload(provider: provider);
  }
}
