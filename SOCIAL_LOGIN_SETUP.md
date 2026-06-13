# Social Login Setup

이 프로젝트는 Google, Kakao, Apple 소셜 로그인 실행 코드와 백엔드 토큰 검증을 포함합니다.
앱에서 실제로 사용하려면 각 제공자 콘솔에서 앱 정보를 등록한 뒤 로컬 설정 파일에 발급값을 넣어야 합니다.

## 현재 앱 식별자

- Android package: `com.maiyard.class_finder`
- iOS bundle id: `com.maiyard.classFinder`
- Apple Android callback endpoint: `/auth/apple/callback`

## 로컬 실행 준비

1. 루트에 소셜 로그인 런타임 설정 파일을 만듭니다.

```powershell
Copy-Item .\social-login.env.example .\social-login.env
```

2. `social-login.env`에 실제 값을 입력합니다.

```properties
API_BASE_URL=http://localhost:3001
GOOGLE_SERVER_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-google-ios-client-id.apps.googleusercontent.com
KAKAO_NATIVE_APP_KEY=your-kakao-native-app-key
KAKAO_CUSTOM_SCHEME=kakaoyour-kakao-native-app-key
APPLE_SERVICE_ID=your.apple.service.id
APPLE_REDIRECT_URI=https://your-api.example.com/auth/apple/callback
```

3. 백엔드 검증용 환경 파일도 맞춥니다.

```powershell
Copy-Item .\backend\.env.example .\backend\.env
```

`backend/.env`에 아래 값을 실제 콘솔 값과 맞춥니다.

```properties
GOOGLE_CLIENT_IDS=your-google-web-client-id.apps.googleusercontent.com,your-google-ios-client-id.apps.googleusercontent.com
APPLE_AUDIENCES=your.apple.service.id,com.maiyard.classFinder
APPLE_ANDROID_PACKAGE_ID=com.maiyard.class_finder
```

4. 백엔드와 Flutter를 함께 실행합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1
```

Android 에뮬레이터에서는:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\run_with_backend.ps1 -DeviceId emulator-5554
```

`run_with_backend.ps1`는 `social-login.env`를 읽어 Flutter `--dart-define`을 자동으로 붙이고, Google iOS URL scheme과 Kakao callback scheme 네이티브 설정 파일을 생성합니다.

## Google 설정

- Google Cloud 또는 Firebase 프로젝트를 만듭니다.
- Android OAuth client에 package `com.maiyard.class_finder`를 등록합니다.
- 디버그/릴리즈 SHA-1, SHA-256을 등록합니다.
- iOS OAuth client에 bundle id `com.maiyard.classFinder`를 등록합니다.
- 백엔드 검증에 사용할 Web client ID를 발급해 `GOOGLE_SERVER_CLIENT_ID`와 `GOOGLE_CLIENT_IDS`에 넣습니다.

## Kakao 설정

- Kakao Developers 앱을 만듭니다.
- Native App Key를 발급합니다.
- Android 플랫폼에 package `com.maiyard.class_finder`와 key hash를 등록합니다.
- iOS 플랫폼에 bundle id `com.maiyard.classFinder`를 등록합니다.
- Kakao Login을 활성화합니다.
- OpenID Connect는 ID 토큰을 함께 쓰려면 활성화합니다. 현재 백엔드는 access token으로 Kakao user API를 검증하므로 필수는 아닙니다.
- callback scheme은 기본적으로 `kakao{NATIVE_APP_KEY}` 형식입니다.

## Apple 설정

- Apple Developer Program 유료 멤버십이 필요합니다.
- App ID `com.maiyard.classFinder`에 `Sign in with Apple` capability를 활성화합니다.
- iOS 타깃에는 `Runner.entitlements`가 연결되어 있습니다. Xcode Signing & Capabilities에서도 같은 capability가 활성화되어 있어야 합니다.
- Android에서도 Apple 로그인을 사용하려면 Service ID를 만들고 Return URL에 `https://your-api.example.com/auth/apple/callback`을 등록합니다.
- 운영 서버의 `/auth/apple/callback`은 Apple callback을 `signinwithapple://callback` Android 앱 intent로 돌려보냅니다.

## 빌드

릴리즈 빌드 전에는 검증 스크립트를 실행합니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\validate_release_config.ps1 `
  -ApiBaseUrl https://your-api.example.com `
  -GoogleServerClientId your-google-web-client-id.apps.googleusercontent.com `
  -GoogleIosClientId your-google-ios-client-id.apps.googleusercontent.com `
  -KakaoNativeAppKey your-kakao-native-app-key `
  -AppleServiceId your.apple.service.id `
  -AppleRedirectUri https://your-api.example.com/auth/apple/callback `
  -RequireGoogle -RequireKakao -RequireApple -CheckBackendEnv
```

빌드는:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_release.ps1 `
  -ApiBaseUrl https://your-api.example.com `
  -Target appbundle `
  -GoogleServerClientId your-google-web-client-id.apps.googleusercontent.com `
  -GoogleIosClientId your-google-ios-client-id.apps.googleusercontent.com `
  -KakaoNativeAppKey your-kakao-native-app-key `
  -AppleServiceId your.apple.service.id `
  -AppleRedirectUri https://your-api.example.com/auth/apple/callback `
  -RequireGoogle -RequireKakao -RequireApple -CheckBackendEnv
```

## 직접 준비할 수 없는 값

다음 값은 개발자 콘솔 계정 권한이 있어야 발급할 수 있습니다.

- Google OAuth client ID, Android SHA 등록
- Kakao Native App Key, Android key hash 등록
- Apple Developer App ID, Service ID, Return URL 등록
- 운영용 HTTPS API 도메인
