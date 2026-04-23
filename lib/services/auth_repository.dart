import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

/// 인증 저장소 추상화 — 로컬 구현 또는 원격(HTTP) 구현을 주입 가능
abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  });
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User> updateProfile(User user);
}

class AuthResult {
  final User user;
  final String token;
  const AuthResult({required this.user, required this.token});
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

// ── 로컬 구현 (SharedPreferences 기반, 백엔드 시뮬레이션) ──────────
class LocalAuthRepository implements AuthRepository {
  static const _usersKey = 'auth.users';      // 등록된 사용자 전체 저장소
  static const _sessionKey = 'auth.session';  // 현재 세션 (userId)
  static const _tokenKey = 'auth.token';      // 현재 토큰

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

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    // 네트워크 지연 시뮬레이션 (실제 백엔드 연동 시 제거)
    await Future.delayed(const Duration(milliseconds: 600));

    final users = await _readUsers();
    final record = users[email.toLowerCase()];
    if (record == null) {
      throw const AuthException('등록되지 않은 이메일입니다.');
    }
    final data = Map<String, dynamic>.from(record as Map);
    final salt = data['salt'] as String;
    final hash = data['passwordHash'] as String;
    if (_hash(password, salt) != hash) {
      throw const AuthException('비밀번호가 일치하지 않습니다.');
    }
    final user = User.fromJson(Map<String, dynamic>.from(data['profile']));
    final token = _randomToken();

    final p = await SharedPreferences.getInstance();
    await p.setString(_sessionKey, user.id);
    await p.setString(_tokenKey, token);

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
      throw const AuthException('이미 사용 중인 이메일입니다.');
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
    final p = await SharedPreferences.getInstance();
    await p.setString(_sessionKey, user.id);
    await p.setString(_tokenKey, token);

    return AuthResult(user: user, token: token);
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
      throw const AuthException('사용자를 찾을 수 없습니다.');
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
    final res = await client.post('/auth/signin',
        {'email': email, 'password': password}, withAuth: false);
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
