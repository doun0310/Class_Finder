import 'package:class_finder/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('normalizes paths without a leading slash', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com/',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://example.com/health');
        return http.Response('{}', 200);
      }),
    );

    await client.get('health', withAuth: false);
    client.dispose();
  });

  test('throws ApiException for invalid JSON responses', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      client: MockClient((_) async => http.Response('not-json', 200)),
    );

    await expectLater(
      client.get('/health', withAuth: false),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 200)
            .having(
              (error) => error.message,
              'message',
              '서버 응답 형식이 올바르지 않습니다.',
            ),
      ),
    );
    client.dispose();
  });

  test('times out stalled requests', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      client.get('/health', withAuth: false),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 0)
            .having((error) => error.message, 'message', contains('초과')),
      ),
    );
    client.dispose();
  });
}
