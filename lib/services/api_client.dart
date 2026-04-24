import 'dart:convert';
import 'package:http/http.dart' as http;

/// 백엔드 서버 통신을 위한 HTTP 클라이언트 (실 서버 연동 시 swap-in)
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

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
    final res = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(withAuth: withAuth),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path, {bool withAuth = true}) async {
    final res = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(withAuth: withAuth),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _errorMessage(res));
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
      if (body is Map && body['message'] is String) return body['message'];
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
