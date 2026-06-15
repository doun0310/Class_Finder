import 'package:class_finder/services/runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports local storage mode when API base URL is absent', () {
    const config = RuntimeConfig(apiBaseUrl: '');

    expect(config.usesBackend, isFalse);
    expect(config.modeBadge, '로컬 저장 모드');
    expect(config.modeTitle, '현재 이 기기에만 저장됩니다');
    expect(
      config.releaseWarnings,
      contains(
        'API_BASE_URL이 없어 서버 저장이 비활성화되어 있습니다. 릴리스 빌드에서는 외부 HTTPS API 주소를 넣어 주세요.',
      ),
    );
  });

  test('flags localhost backend URLs as release warnings', () {
    const config = RuntimeConfig(apiBaseUrl: 'http://localhost:3001');

    expect(config.usesBackend, isTrue);
    expect(config.usesLocalhostBackend, isTrue);
    expect(config.modeHint, contains('로컬 주소'));
    expect(
      config.releaseWarnings,
      contains(
        'API_BASE_URL이 localhost 계열 주소입니다. 실서비스에서는 외부 HTTPS API 주소가 필요합니다.',
      ),
    );
  });

  test('tracks social provider release readiness', () {
    const config = RuntimeConfig(
      apiBaseUrl: 'https://api.example.com',
      googleServerClientId: 'google-server',
      kakaoNativeAppKey: 'kakao-key',
      appleServiceId: 'apple-service',
      appleRedirectUri: 'https://api.example.com/auth/apple/callback',
    );

    expect(config.googleConfigured, isTrue);
    expect(config.kakaoConfigured, isTrue);
    expect(config.appleWebFlowConfigured, isTrue);
    expect(config.releaseWarnings, isEmpty);
  });
}
