import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'auth_repository.dart';
import 'social_auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  final AuthRepository _repo;
  final SocialAuthGateway _socialAuth;

  AuthService(this._repo, {required SocialAuthGateway socialAuth})
    : _socialAuth = socialAuth;

  User? _user;
  String? _token;
  AuthStatus _status = AuthStatus.unknown;
  String? _lastError;
  AuthErrorCode? _lastErrorCode;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get lastError => _lastError;
  AuthErrorCode? get lastErrorCode => _lastErrorCode;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _repo.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth.token');
      if (user != null && token != null) {
        _user = user;
        _token = token;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _token = null;
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _beginLoading();
    try {
      final result = await _repo.signIn(email: email, password: password);
      _applySession(result);
      return true;
    } on AuthException catch (error) {
      _captureAuthError(error);
      return false;
    } catch (_) {
      _captureUnknownError('로그인 중 오류가 발생했습니다.');
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<bool> signInWithProvider(AuthProvider provider) async {
    _beginLoading();
    try {
      final payload = await _socialAuth.authenticate(provider);
      final result = await _repo.signInWithProvider(provider, payload: payload);
      _applySession(result);
      return true;
    } on AuthException catch (error) {
      _captureAuthError(error);
      return false;
    } catch (_) {
      _captureUnknownError('${provider.label} 로그인 중 오류가 발생했습니다.');
      return false;
    } finally {
      _finishLoading();
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
    _beginLoading();
    try {
      final result = await _repo.signUp(
        email: email,
        password: password,
        name: name,
        studentId: studentId,
        department: department,
        grade: grade,
      );
      _applySession(result);
      return true;
    } on AuthException catch (error) {
      _captureAuthError(error);
      return false;
    } catch (_) {
      _captureUnknownError('회원가입 중 오류가 발생했습니다.');
      return false;
    } finally {
      _finishLoading();
    }
  }

  Future<String?> requestPasswordReset({required String email}) async {
    _beginLoading();
    try {
      return await _repo.requestPasswordReset(email: email);
    } on AuthException catch (error) {
      _captureAuthError(error);
      return null;
    } catch (_) {
      _captureUnknownError('비밀번호 재설정 요청 중 오류가 발생했습니다.');
      return null;
    } finally {
      _finishLoading();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _lastError = null;
    _lastErrorCode = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? studentId,
    String? department,
    int? grade,
  }) async {
    if (_user == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _repo.updateProfile(
        _user!.copyWith(
          name: name,
          studentId: studentId,
          department: department,
          grade: grade,
        ),
      );
      _user = updated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    _lastErrorCode = null;
    notifyListeners();
  }

  void _beginLoading() {
    _isLoading = true;
    _lastError = null;
    _lastErrorCode = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _applySession(AuthResult result) {
    _user = result.user;
    _token = result.token;
    _status = AuthStatus.authenticated;
  }

  void _captureAuthError(AuthException error) {
    _lastErrorCode = error.code;
    _lastError = error.message;
  }

  void _captureUnknownError(String message) {
    _lastErrorCode = AuthErrorCode.unknown;
    _lastError = message;
  }
}
