import 'dart:convert';

import 'package:class_finder/services/api_client.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalAuthRepository', () {
    late LocalAuthRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalAuthRepository();
    });

    test('returns generic password reset message for any email', () async {
      final unknownMessage = await repository.requestPasswordReset(
        email: 'missing@example.com',
      );

      await repository.signUp(
        email: 'student@example.com',
        password: 'password123',
        name: 'Student Kim',
        studentId: '20230001',
        department: 'Computer Science',
        grade: 2,
      );

      final existingMessage = await repository.requestPasswordReset(
        email: 'student@example.com',
      );

      expect(unknownMessage, existingMessage);
      expect(unknownMessage, contains('등록되어 있다면'));
    });

    test('locks sign in after repeated wrong password attempts', () async {
      await repository.signUp(
        email: 'student@example.com',
        password: 'password123',
        name: 'Student Kim',
        studentId: '20230001',
        department: 'Computer Science',
        grade: 2,
      );

      for (var index = 0; index < 4; index++) {
        await expectLater(
          repository.signIn(
            email: 'student@example.com',
            password: 'wrong-password',
          ),
          throwsA(
            isA<AuthException>().having(
              (error) => error.code,
              'code',
              AuthErrorCode.wrongPassword,
            ),
          ),
        );
      }

      await expectLater(
        repository.signIn(
          email: 'student@example.com',
          password: 'wrong-password',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            AuthErrorCode.tooManyAttempts,
          ),
        ),
      );

      await expectLater(
        repository.signIn(
          email: 'student@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            AuthErrorCode.tooManyAttempts,
          ),
        ),
      );
    });

    test('reuses provisioned social account on subsequent sign-ins', () async {
      final first = await repository.signInWithProvider(AuthProvider.google);
      await repository.signOut();
      final second = await repository.signInWithProvider(AuthProvider.google);

      expect(first.user.email, AuthProvider.google.seedEmail);
      expect(first.user.studentId, isEmpty);
      expect(first.user.department, isEmpty);
      expect(first.user.grade, 1);
      expect(first.user.profileComplete, isFalse);
      expect(second.user.id, first.user.id);
      expect(second.user.email, first.user.email);
      expect(second.user.profileComplete, isFalse);
    });

    test('ignores corrupted local auth cache', () async {
      SharedPreferences.setMockInitialValues({
        'auth.users': 'not-json',
        'auth.loginAttempts': 'not-json',
        'auth.session': 'missing-user',
        'auth.token': 'stale-token',
      });
      repository = LocalAuthRepository();

      expect(await repository.getCurrentUser(), isNull);
      await expectLater(
        repository.signIn(
          email: 'student@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            AuthErrorCode.userNotFound,
          ),
        ),
      );
    });
  });

  group('RemoteAuthRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('maps social token rejection to socialUnavailable', () async {
      final apiClient = ApiClient(
        baseUrl: 'http://example.com',
        client: MockClient((request) async {
          expect(request.url.path, '/auth/social-signin');
          return http.Response(
            jsonEncode({'message': 'Google token verification failed.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = RemoteAuthRepository(apiClient);

      await expectLater(
        repository.signInWithProvider(
          AuthProvider.google,
          payload: const SocialAuthPayload(
            provider: AuthProvider.google,
            idToken: 'invalid-token',
          ),
        ),
        throwsA(
          isA<AuthException>()
              .having(
                (error) => error.code,
                'code',
                AuthErrorCode.socialUnavailable,
              )
              .having((error) => error.message, 'message', contains('Google')),
        ),
      );

      apiClient.dispose();
    });
  });
}
