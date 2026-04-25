import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

/// 인증 저장소 추상화 — 로컬 구현 또는 원격(HTTP) 구현을 주입 가능
abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<AuthResult> signInWithProvider(AuthProvider provider);
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
    AuthProvider.google => 'Google 사용자',
    AuthProvider.kakao => 'Kakao 사용자',
    AuthProvider.apple => 'Apple 사용자',
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

// ── 로컬 구현 (SharedPreferences 기반, 백엔드 시뮬레이션) ──────────
class LocalAuthRepository implements AuthRepository {
  static const _usersKey = 'auth.users'; // 등록된 사용자 전체 저장소
  static const _sessionKey = 'auth.session'; // 현재 세션 (userId)
  static const _tokenKey = 'auth.token'; // 현재 토큰
  static const _attemptsKey = 'auth.loginAttempts'; // 로그인 실패 횟수/잠금 상태

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
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeUsers(Map<String, dynamic> users) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_usersKey, jsonEncode(users));
  }

  Future<Map<String, dynamic>> _readAttempts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_attemptsKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _writeAttempts(Map<String, dynamic> attempts) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_attemptsKey, jsonEncode(attempts));
  }

  Future<void> _persistSession(User user, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_sessionKey, user.id);
    await p.setString(_tokenKey, token);
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    // 네트워크 지연 시뮬레이션 (실제 백엔드 연동 시 제거)
    await Future.delayed(const Duration(milliseconds: 600));

    final emailKey = email.toLowerCase();
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
          '로그인 시도가 너무 많습니다. 약 ${seconds.toString()}초 후 다시 시도해주세요.',
        );
      }
    }

    final record = users[emailKey];
    if (record == null) {
      throw const AuthException(AuthErrorCode.userNotFound, '가입되지 않은 이메일입니다.');
    }
    final data = Map<String, dynamic>.from(record as Map);
    final salt = data['salt'] as String;
    final hash = data['passwordHash'] as String;
    if (_hash(password, salt) != hash) {
      final failureCount = (attemptData['count'] as num? ?? 0).toInt() + 1;

      if (failureCount >= 5) {
        attempts[emailKey] = {
          'count': 0,
          'lockedUntil': now.add(const Duration(seconds: 30)).toIso8601String(),
        };
        await _writeAttempts(attempts);
        throw const AuthException(
          AuthErrorCode.tooManyAttempts,
          '로그인 시도가 너무 많습니다. 30초 후 다시 시도해주세요.',
        );
      }

      attempts[emailKey] = {'count': failureCount};
      await _writeAttempts(attempts);

      final remaining = 5 - failureCount;
      throw AuthException(
        AuthErrorCode.wrongPassword,
        '비밀번호가 일치하지 않습니다. $remaining회 더 실패하면 잠시 로그인이 제한됩니다.',
      );
    }
    final user = User.fromJson(Map<String, dynamic>.from(data['profile']));
    final token = _randomToken();
    attempts.remove(emailKey);
    await _writeAttempts(attempts);
    await _persistSession(user, token);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<AuthResult> signInWithProvider(AuthProvider provider) async {
    await Future.delayed(const Duration(milliseconds: 550));

    final users = await _readUsers();
    final emailKey = provider.seedEmail;
    final existing = users[emailKey];
    final token = _randomToken();

    if (existing != null) {
      final data = Map<String, dynamic>.from(existing as Map);
      final user = User.fromJson(Map<String, dynamic>.from(data['profile']));
      await _persistSession(user, token);
      return AuthResult(user: user, token: token);
    }

    final user = User(
      id: _randomToken(),
      email: emailKey,
      name: provider.seedName,
      studentId: '20240000',
      department: '컴퓨터공학과',
      grade: 2,
      createdAt: DateTime.now(),
    );
    final salt = _randomToken();

    users[emailKey] = {
      'passwordHash': _hash(_randomToken(), salt),
      'salt': salt,
      'profile': user.toJson(),
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

    final emailKey = email.toLowerCase();
    final users = await _readUsers();
    if (users.containsKey(emailKey)) {
      throw const AuthException(
        AuthErrorCode.emailAlreadyInUse,
        '이미 사용 중인 이메일입니다.',
      );
    }
    if (password.length < 6) {
      throw const AuthException(
        AuthErrorCode.weakPassword,
        '비밀번호는 6자 이상이어야 합니다.',
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
    return '입력한 이메일이 등록되어 있다면 비밀번호 재설정 안내를 전송했습니다.';
  }

  @override
  Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_sessionKey);
    await p.remove(_tokenKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    final userId = p.getString(_sessionKey);
    if (userId == null) return null;
    final users = await _readUsers();
    for (final entry in users.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      final profile = Map<String, dynamic>.from(data['profile']);
      if (profile['id'] == userId) return User.fromJson(profile);
    }
    return null;
  }

  @override
  Future<User> updateProfile(User user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readUsers();
    final emailKey = user.email.toLowerCase();
    if (!users.containsKey(emailKey)) {
      throw const AuthException(AuthErrorCode.userNotFound, '사용자를 찾을 수 없습니다.');
    }
    final data = Map<String, dynamic>.from(users[emailKey] as Map);
    data['profile'] = user.toJson();
    users[emailKey] = data;
    await _writeUsers(users);
    return user;
  }
}

// ── 원격(HTTP) 구현 — 실 서버 연동 시 사용 ────────────────────────
class RemoteAuthRepository implements AuthRepository {
  final ApiClient client;
  RemoteAuthRepository(this.client);

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await client.post('/auth/signin', {
      'email': email,
      'password': password,
    }, withAuth: false);
    final token = res['token'] as String;
    client.setToken(token);
    return AuthResult(
      user: User.fromJson(Map<String, dynamic>.from(res['user'] as Map)),
      token: token,
    );
  }

  @override
  Future<AuthResult> signInWithProvider(AuthProvider provider) async {
    final res = await client.post('/auth/social-signin', {
      'provider': provider.name,
    }, withAuth: false);
    final token = res['token'] as String;
    client.setToken(token);
    return AuthResult(
      user: User.fromJson(Map<String, dynamic>.from(res['user'] as Map)),
      token: token,
    );
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
    final res = await client.post('/auth/signup', {
      'email': email,
      'password': password,
      'name': name,
      'studentId': studentId,
      'department': department,
      'grade': grade,
    }, withAuth: false);
    final token = res['token'] as String;
    client.setToken(token);
    return AuthResult(
      user: User.fromJson(Map<String, dynamic>.from(res['user'] as Map)),
      token: token,
    );
  }

  @override
  Future<String> requestPasswordReset({required String email}) async {
    final res = await client.post('/auth/password-reset', {
      'email': email,
    }, withAuth: false);
    return res['message'] as String? ?? '비밀번호 재설정 안내를 전송했습니다.';
  }

  @override
  Future<void> signOut() async {
    try {
      await client.post('/auth/signout', {});
    } finally {
      client.setToken(null);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final res = await client.get('/auth/me');
      return User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    final res = await client.post('/users/${user.id}', user.toJson());
    return User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
  }
}
