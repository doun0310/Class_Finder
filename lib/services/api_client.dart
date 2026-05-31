import 'dart:convert';

import 'package:http/http.dart' as http;

/// 백엔드 서버와 통신하기 위한 공용 HTTP 클라이언트입니다.
class ApiClient {
  static const _networkErrorMessage =
      '서버에 연결할 수 없습니다. 백엔드 실행 상태와 네트워크를 확인해 주세요.';

  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiClient({required String baseUrl, http.Client? client})
    : baseUrl = baseUrl.endsWith('/')
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
      () => _client.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers(withAuth: withAuth),
      ),
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
        Uri.parse('$baseUrl$path'),
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
        Uri.parse('$baseUrl$path'),
        headers: _headers(withAuth: withAuth),
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<void> delete(String path, {bool withAuth = true}) async {
    final res = await _send(
      () => _client.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(withAuth: withAuth),
      ),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      throw const ApiException(0, _networkErrorMessage);
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
    }
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] is String) {
        return body['message'];
      }
      if (body is Map && body['message'] is List) {
        return (body['message'] as List).join(', ');
      }
    } catch (_) {}
    return '서버 오류 (${res.statusCode})';
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
