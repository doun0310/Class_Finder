import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared HTTP client for backend API calls.
class ApiClient {
  static const _networkErrorMessage =
      '서버에 연결할 수 없습니다. 백엔드 실행 상태와 네트워크를 확인해 주세요.';
  static const _invalidResponseMessage = '서버 응답 형식이 올바르지 않습니다.';
  static const _timeoutMessage = '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해 주세요.';

  final String baseUrl;
  final http.Client _client;
  final Duration requestTimeout;
  String? _token;

  ApiClient({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client();

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path, {bool withAuth = true}) async {
    final res = await _send(
      () => _client.get(_uri(path), headers: _headers(withAuth: withAuth)),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final res = await _send(
      () => _client.post(
        _uri(path),
        headers: _headers(withAuth: withAuth),
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final res = await _send(
      () => _client.patch(
        _uri(path),
        headers: _headers(withAuth: withAuth),
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<void> delete(String path, {bool withAuth = true}) async {
    final res = await _send(
      () => _client.delete(_uri(path), headers: _headers(withAuth: withAuth)),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiException(0, _timeoutMessage);
    } on http.ClientException {
      throw const ApiException(0, _networkErrorMessage);
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    if (res.body.isEmpty) return {};

    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
    } on FormatException {
      throw ApiException(res.statusCode, _invalidResponseMessage);
    }

    throw ApiException(res.statusCode, _invalidResponseMessage);
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      if (body is Map && body['message'] is List) {
        return (body['message'] as List).join(', ');
      }
    } catch (_) {}
    return '서버 오류 (${res.statusCode})';
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
