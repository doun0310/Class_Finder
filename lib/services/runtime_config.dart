class RuntimeConfig {
  final String apiBaseUrl;
  final String googleServerClientId;
  final String googleIosClientId;
  final String kakaoNativeAppKey;
  final String kakaoCustomScheme;
  final String appleServiceId;
  final String appleRedirectUri;

  const RuntimeConfig({
    required this.apiBaseUrl,
    this.googleServerClientId = '',
    this.googleIosClientId = '',
    this.kakaoNativeAppKey = '',
    this.kakaoCustomScheme = '',
    this.appleServiceId = '',
    this.appleRedirectUri = '',
  });

  const RuntimeConfig.fromEnvironment()
    : apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
      googleServerClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ),
      googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      kakaoNativeAppKey = const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'),
      kakaoCustomScheme = const String.fromEnvironment('KAKAO_CUSTOM_SCHEME'),
      appleServiceId = const String.fromEnvironment('APPLE_SERVICE_ID'),
      appleRedirectUri = const String.fromEnvironment('APPLE_REDIRECT_URI');

  bool get usesBackend => apiBaseUrl.isNotEmpty;

  bool get usesLocalhostBackend {
    final normalized = apiBaseUrl.toLowerCase();
    return normalized.contains('localhost') ||
        normalized.contains('127.0.0.1') ||
        normalized.contains('10.0.2.2');
  }

  bool get googleConfigured =>
      googleServerClientId.isNotEmpty || googleIosClientId.isNotEmpty;

  bool get kakaoConfigured => kakaoNativeAppKey.isNotEmpty;

  bool get appleWebFlowConfigured =>
      appleServiceId.isNotEmpty && appleRedirectUri.isNotEmpty;

  String get modeBadge => usesBackend ? '서버 저장 모드' : '로컬 저장 모드';

  String get modeTitle => usesBackend ? '현재 서버와 연결되어 있습니다' : '현재 이 기기에만 저장됩니다';

  String get modeDescription => usesBackend
      ? '계정과 시간표가 서버에 저장됩니다.'
      : '현재는 이 기기 안에만 저장됩니다. 서버 저장이 필요하면 run_with_backend.ps1 또는 API_BASE_URL로 실행하세요.';

  String? get modeHint => usesLocalhostBackend
      ? '현재 API_BASE_URL이 로컬 주소를 가리키고 있습니다. 실배포 빌드에서는 외부에서 접근 가능한 HTTPS 주소로 바꾸세요.'
      : null;

  List<String> get releaseWarnings {
    final warnings = <String>[];

    if (!usesBackend) {
      warnings.add(
        'API_BASE_URL이 없어 서버 저장이 비활성화되어 있습니다. 릴리스 빌드에서는 외부 HTTPS API 주소를 넣어 주세요.',
      );
    } else if (usesLocalhostBackend) {
      warnings.add(
        'API_BASE_URL이 localhost 계열 주소입니다. 실서비스에서는 외부 HTTPS API 주소가 필요합니다.',
      );
    }

    if (!googleConfigured) {
      warnings.add('Google 로그인 클라이언트 ID가 설정되지 않았습니다.');
    }
    if (!kakaoConfigured) {
      warnings.add('Kakao Native App Key가 설정되지 않았습니다.');
    }
    if (!appleWebFlowConfigured) {
      warnings.add(
        'Apple Service ID 또는 Redirect URI가 비어 있습니다. Android 등 웹 플로우가 필요한 플랫폼에서는 Apple 로그인을 사용할 수 없습니다.',
      );
    }

    return warnings;
  }
}
