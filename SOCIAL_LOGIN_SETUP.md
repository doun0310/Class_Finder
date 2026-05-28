# Social Login Setup

이 프로젝트는 앱 코드 기준으로 Google, Kakao, Apple 로그인 흐름을 받을 수 있게 준비되어 있습니다.
다만 실제 로그인 성공까지는 각 플랫폼 콘솔 설정과 키 발급이 반드시 필요합니다.

## Current App Identifiers

- Android package: `com.maiyard.class_finder`
- iOS bundle id: `com.maiyard.classFinder`

## Dart Defines

실행 시 아래 값을 넣어야 합니다.

```bash
flutter run ^
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_SERVER_CLIENT_ID ^
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_GOOGLE_IOS_CLIENT_ID ^
  --dart-define=KAKAO_NATIVE_APP_KEY=YOUR_KAKAO_NATIVE_APP_KEY ^
  --dart-define=KAKAO_CUSTOM_SCHEME=kakaoYOUR_KAKAO_NATIVE_APP_KEY ^
  --dart-define=APPLE_SERVICE_ID=YOUR_APPLE_SERVICE_ID ^
  --dart-define=APPLE_REDIRECT_URI=YOUR_APPLE_REDIRECT_URI
```

## Google

- Google Cloud Console 또는 Firebase 프로젝트 생성
- Android OAuth 앱 등록
- 패키지명 `com.maiyard.class_finder` 등록
- Android SHA-1, SHA-256 지문 등록
- iOS OAuth 앱 등록
- 번들 ID `com.maiyard.classFinder` 등록
- iOS Client ID 발급
- iOS `Info.plist`에 reversed client id URL scheme 추가
- 서버에서 토큰 검증이 필요하면 Web client 또는 server client ID 발급

## Kakao

- Kakao Developers 앱 생성
- Native App Key 발급
- Android 플랫폼에 패키지명 `com.maiyard.class_finder` 등록
- Android key hash 등록
- iOS 플랫폼에 번들 ID `com.maiyard.classFinder` 등록
- Kakao Login 활성화
- 필요 시 OpenID Connect 활성화
- AndroidManifest.xml, Info.plist에 `kakao{NATIVE_APP_KEY}` URL scheme 반영

Android 예시:

```xml
<activity
    android:name="com.kakao.sdk.flutter.auth.AppsHandlerActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="kakaoYOUR_NATIVE_APP_KEY" android:host="oauth" />
    </intent-filter>
</activity>
```

iOS 예시:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakaoYOUR_NATIVE_APP_KEY</string>
    </array>
  </dict>
</array>
```

## Apple

- Apple Developer Program 등록
- App ID에 `Sign in with Apple` capability 활성화
- Xcode target에도 `Sign in with Apple` capability 추가
- Android에서 Apple 로그인까지 지원하려면 Service ID 생성
- Return URL 등록
- 필요 시 private key 생성 후 서버 검증 로직 구성

## Backend Requirement

현재 `RemoteAuthRepository`는 `/auth/social-signin`으로 아래 값을 보내도록 확장되어 있습니다.

- `provider`
- `providerUserId`
- `email`
- `displayName`
- `idToken`
- `accessToken`
- `authorizationCode`

실서비스에서는 서버가 provider별 토큰을 검증하고 내부 세션 또는 JWT를 다시 발급해야 합니다.
