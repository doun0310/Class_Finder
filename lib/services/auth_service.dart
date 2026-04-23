import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// 인증 상태 관리 (Provider로 앱 전역 공유)
class AuthService extends ChangeNotifier {
  final AuthRepository _repo;

  AuthService(this._repo);

  User? _user;
  String? _token;
  AuthStatus _status = AuthStatus.unknown;
  String? _lastError;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _repo.getCurrentUser();
      final p = await SharedPreferences.getInstance();
      final token = p.getString('auth.token');
      if (user != null && token != null) {
        _user = user;
        _token = token;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _repo.signIn(email: email, password: password);
      _user = result.user;
      _token = result.token;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      return false;
    } catch (e) {
      _lastError = '로그인 중 오류가 발생했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _repo.signUp(
        email: email,
        password: password,
        name: name,
        studentId: studentId,
        department: department,
        grade: grade,
      );
      _user = result.user;
      _token = result.token;
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      return false;
    } catch (e) {
      _lastError = '회원가입 중 오류가 발생했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? studentId,
    String? department,
    int? grade,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _repo.updateProfile(_user!.copyWith(
        name: name,
        studentId: studentId,
        department: department,
        grade: grade,
      ));
      _user = updated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
