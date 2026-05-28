import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  });
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  });
  Future<String> requestPasswordReset({required String email});
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User> updateProfile(User user);
}

class AuthResult {
  final User user;
  final String token;

  const AuthResult({required this.user, required this.token});
}

enum AuthProvider { google, kakao, apple }

extension AuthProviderX on AuthProvider {
  String get label => switch (this) {
    AuthProvider.google => 'Google',
    AuthProvider.kakao => 'Kakao',
    AuthProvider.apple => 'Apple',
  };

  String get seedEmail => switch (this) {
    AuthProvider.google => 'google.user@classfinder.app',
    AuthProvider.kakao => 'kakao.user@classfinder.app',
    AuthProvider.apple => 'apple.user@classfinder.app',
  };

  String get seedName => switch (this) {
    AuthProvider.google => 'Google User',
    AuthProvider.kakao => 'Kakao User',
    AuthProvider.apple => 'Apple User',
  };
}

class SocialAuthPayload {
  final AuthProvider provider;
  final String? providerUserId;
  final String? email;
  final String? displayName;
  final String? idToken;
  final String? accessToken;
  final String? authorizationCode;

  const SocialAuthPayload({
    required this.provider,
    this.providerUserId,
    this.email,
    this.displayName,
    this.idToken,
    this.accessToken,
    this.authorizationCode,
  });

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'providerUserId': providerUserId,
    'email': email,
    'displayName': displayName,
    'idToken': idToken,
    'accessToken': accessToken,
    'authorizationCode': authorizationCode,
  };
}

enum AuthErrorCode {
  userNotFound,
  wrongPassword,
  tooManyAttempts,
  emailAlreadyInUse,
  weakPassword,
  network,
  socialUnavailable,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorCode code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class LocalAuthRepository implements AuthRepository {
  static const _usersKey = 'auth.users';
  static const _sessionKey = 'auth.session';
  static const _tokenKey = 'auth.token';
  static const _attemptsKey = 'auth.loginAttempts';

  static String _hash(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    return sha256.convert(bytes).toString();
  }

  static String _randomToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(24, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }

  Future<Map<String, dynamic>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) {
      return {};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<Map<String, dynamic>> _readAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    if (raw == null) {
      return {};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeAttempts(Map<String, dynamic> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attemptsKey, jsonEncode(attempts));
  }

  Future<void> _persistSession(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, user.id);
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailKey = email.trim().toLowerCase();
    final users = await _readUsers();
    final attempts = await _readAttempts();
    final now = DateTime.now();
    final attemptData = Map<String, dynamic>.from(
      attempts[emailKey] as Map? ?? const {},
    );
    final lockedUntilRaw = attemptData['lockedUntil'] as String?;

    if (lockedUntilRaw != null) {
      final lockedUntil = DateTime.tryParse(lockedUntilRaw);
      if (lockedUntil != null && lockedUntil.isAfter(now)) {
        final seconds = lockedUntil.difference(now).inSeconds.clamp(1, 999);
        throw AuthException(
          AuthErrorCode.tooManyAttempts,
          'Too many login attempts. Try again in ${seconds}s.',
        );
      }
    }

    final record = users[emailKey];
    if (record == null) {
      throw const AuthException(
        AuthErrorCode.userNotFound,
        'This email is not registered.',
      );
    }

    final data = Map<String, dynamic>.from(record as Map);
    final salt = data['salt'] as String;
    final hash = data['passwordHash'] as String;
    if (_hash(password, salt) != hash) {
      final failureCount = (attemptData['count'] as num? ?? 0).toInt() + 1;
      if (failureCount >= 5) {
        attempts[emailKey] = {
          'count': 0,
          'lockedUntil': now
              .add(const Duration(seconds: 30))
              .toIso8601String(),
        };
        await _writeAttempts(attempts);
        throw const AuthException(
          AuthErrorCode.tooManyAttempts,
          'Too many login attempts. Try again in 30s.',
        );
      }

      attempts[emailKey] = {'count': failureCount};
      await _writeAttempts(attempts);

      final remaining = 5 - failureCount;
      throw AuthException(
        AuthErrorCode.wrongPassword,
        'Wrong password. $remaining attempt(s) remaining before lockout.',
      );
    }

    final user = User.fromJson(Map<String, dynamic>.from(data['profile'] as Map));
    final token = _randomToken();
    attempts.remove(emailKey);
    await _writeAttempts(attempts);
    await _persistSession(user, token);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final users = await _readUsers();
    final token = _randomToken();
    final emailKey =
        (payload?.email?.trim().isNotEmpty ?? false)
            ? payload!.email!.trim().toLowerCase()
            : provider.seedEmail;
    final existing = users[emailKey];

    if (existing != null) {
      final data = Map<String, dynamic>.from(existing as Map);
      final existingProfile = User.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map),
      );
      final mergedUser = existingProfile.copyWith(
        name: payload?.displayName ?? existingProfile.name,
      );
      data['profile'] = mergedUser.toJson();
      users[emailKey] = data;
      await _writeUsers(users);
      await _persistSession(mergedUser, token);
      return AuthResult(user: mergedUser, token: token);
    }

    final user = User(
      id: _randomToken(),
      email: emailKey,
      name:
          (payload?.displayName?.trim().isNotEmpty ?? false)
              ? payload!.displayName!.trim()
              : provider.seedName,
      studentId: '20240000',
      department: 'Computer Science',
      grade: 2,
      createdAt: DateTime.now(),
    );
    final salt = _randomToken();

    users[emailKey] = {
      'passwordHash': _hash(_randomToken(), salt),
      'salt': salt,
      'profile': user.toJson(),
      'social': payload?.toJson(),
    };
    await _writeUsers(users);
    await _persistSession(user, token);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final emailKey = email.trim().toLowerCase();
    final users = await _readUsers();
    if (users.containsKey(emailKey)) {
      throw const AuthException(
        AuthErrorCode.emailAlreadyInUse,
        'This email is already in use.',
      );
    }
    if (password.length < 6) {
      throw const AuthException(
        AuthErrorCode.weakPassword,
        'Password must be at least 6 characters.',
      );
    }

    final salt = _randomToken();
    final id = _randomToken();
    final user = User(
      id: id,
      email: emailKey,
      name: name,
      studentId: studentId,
      department: department,
      grade: grade,
      createdAt: DateTime.now(),
    );

    users[emailKey] = {
      'passwordHash': _hash(password, salt),
      'salt': salt,
      'profile': user.toJson(),
    };
    await _writeUsers(users);

    final token = _randomToken();
    await _persistSession(user, token);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<String> requestPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 650));
    return 'If the email exists, password reset instructions have been sent.';
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionKey);
    if (userId == null) {
      return null;
    }

    final users = await _readUsers();
    for (final entry in users.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      final profile = Map<String, dynamic>.from(data['profile'] as Map);
      if (profile['id'] == userId) {
        return User.fromJson(profile);
      }
    }

    return null;
  }

  @override
  Future<User> updateProfile(User user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readUsers();
    final emailKey = user.email.toLowerCase();
    if (!users.containsKey(emailKey)) {
      throw const AuthException(
        AuthErrorCode.userNotFound,
        'User not found.',
      );
    }

    final data = Map<String, dynamic>.from(users[emailKey] as Map);
    data['profile'] = user.toJson();
    users[emailKey] = data;
    await _writeUsers(users);
    return user;
  }
}

class RemoteAuthRepository implements AuthRepository {
  static const _sessionKey = 'auth.session';
  static const _tokenKey = 'auth.token';

  final ApiClient client;

  RemoteAuthRepository(this.client);

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post('/auth/signin', {
        'email': email,
        'password': password,
      }, withAuth: false);
      return _consumeAuthResult(response);
    } on ApiException catch (error) {
      throw _mapApiException(error);
    }
  }

  @override
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  }) async {
    try {
      final response = await client.post('/auth/social-signin', {
        'provider': provider.name,
        if (payload != null) ...payload.toJson(),
      }, withAuth: false);
      return _consumeAuthResult(response);
    } on ApiException catch (error) {
      throw _mapApiException(error, provider: provider);
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  }) async {
    try {
      final response = await client.post('/auth/signup', {
        'email': email,
        'password': password,
        'name': name,
        'studentId': studentId,
        'department': department,
        'grade': grade,
      }, withAuth: false);
      return _consumeAuthResult(response);
    } on ApiException catch (error) {
      throw _mapApiException(error);
    }
  }

  @override
  Future<String> requestPasswordReset({required String email}) async {
    try {
      final response = await client.post('/auth/password-reset', {
        'email': email,
      }, withAuth: false);
      return response['message'] as String? ??
          'If the email exists, password reset instructions have been sent.';
    } on ApiException catch (error) {
      throw _mapApiException(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _restoreToken();
    try {
      await client.post('/auth/signout', {});
    } on ApiException {
      // Clear the local session even if the server session is already gone.
    } finally {
      client.setToken(null);
      await _clearSession();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = await _restoreToken();
      if (token == null) {
        return null;
      }

      final response = await client.get('/auth/me');
      return User.fromJson(
        Map<String, dynamic>.from(response['user'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      await _restoreToken();
      final response = await client.patch('/auth/me', {
        'name': user.name,
        'studentId': user.studentId,
        'department': user.department,
        'grade': user.grade,
      });
      return User.fromJson(
        Map<String, dynamic>.from(response['user'] as Map),
      );
    } on ApiException catch (error) {
      throw _mapApiException(error);
    }
  }

  Future<AuthResult> _consumeAuthResult(Map<String, dynamic> response) async {
    final token = response['token'] as String;
    final user = User.fromJson(
      Map<String, dynamic>.from(response['user'] as Map),
    );
    client.setToken(token);
    await _persistSession(user, token);
    return AuthResult(user: user, token: token);
  }

  Future<void> _persistSession(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, user.id);
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    client.setToken(token);
    return token;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  AuthException _mapApiException(
    ApiException error, {
    AuthProvider? provider,
  }) {
    switch (error.statusCode) {
      case 400:
        if (error.message.toLowerCase().contains('password')) {
          return const AuthException(
            AuthErrorCode.weakPassword,
            '비밀번호는 6자 이상이어야 합니다.',
          );
        }
        return AuthException(AuthErrorCode.unknown, error.message);
      case 401:
        return const AuthException(
          AuthErrorCode.wrongPassword,
          '비밀번호가 일치하지 않습니다.',
        );
      case 404:
        return const AuthException(
          AuthErrorCode.userNotFound,
          '가입되지 않은 이메일입니다.',
        );
      case 409:
        return const AuthException(
          AuthErrorCode.emailAlreadyInUse,
          '이미 사용 중인 이메일입니다.',
        );
      case 429:
        return const AuthException(
          AuthErrorCode.tooManyAttempts,
          '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.',
        );
      case 503:
        return AuthException(
          AuthErrorCode.socialUnavailable,
          '${provider?.label ?? '소셜'} 로그인을 지금 사용할 수 없습니다.',
        );
      default:
        return AuthException(AuthErrorCode.network, error.message);
    }
  }
}
