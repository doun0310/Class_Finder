import 'package:class_finder/services/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
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
        name: '홍길동',
        studentId: '20230001',
        department: '컴퓨터공학과',
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
        name: '홍길동',
        studentId: '20230001',
        department: '컴퓨터공학과',
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
      expect(second.user.id, first.user.id);
      expect(second.user.email, first.user.email);
    });
  });
}
