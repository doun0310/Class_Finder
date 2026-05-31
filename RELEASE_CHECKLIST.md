# Release Checklist

## 1. Backend Environment

- Copy `backend/.env.production.example` to `backend/.env.production`
- Set `DATABASE_URL` to the production PostgreSQL instance
- Set `CORS_ORIGIN` to the real frontend origin
- Confirm the backend is reachable from the app over HTTPS

## 2. Flutter Dart Defines

Required:

- `API_BASE_URL`

Optional but required if you expose each provider in production:

- `GOOGLE_SERVER_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `KAKAO_NATIVE_APP_KEY`
- `KAKAO_CUSTOM_SCHEME`
- `APPLE_SERVICE_ID`
- `APPLE_REDIRECT_URI`

## 3. Validate Release Configuration

Create Android signing settings first:

```powershell
Copy-Item .\android\key.properties.example .\android\key.properties
```

Then fill these values in `android/key.properties`:

- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\validate_release_config.ps1 `
  -ApiBaseUrl https://api.example.com `
  -Target appbundle `
  -GoogleServerClientId YOUR_GOOGLE_SERVER_CLIENT_ID `
  -GoogleIosClientId YOUR_GOOGLE_IOS_CLIENT_ID `
  -KakaoNativeAppKey YOUR_KAKAO_NATIVE_APP_KEY `
  -KakaoCustomScheme kakaoYOUR_KAKAO_NATIVE_APP_KEY `
  -AppleServiceId YOUR_APPLE_SERVICE_ID `
  -AppleRedirectUri https://api.example.com/auth/apple/callback `
  -RequireGoogle `
  -RequireKakao `
  -RequireApple `
  -CheckBackendEnv
```

## 4. Run Full Release Checks

```powershell
flutter analyze
flutter test
cd backend
npm run build
npm run test:e2e
```

Or run the consolidated script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_release.ps1 `
  -ApiBaseUrl https://api.example.com `
  -Target appbundle `
  -RequireGoogle `
  -RequireKakao `
  -RequireApple `
  -CheckBackendEnv
```

The build script also generates:

- `android/social-login.properties`
- `ios/Flutter/SocialLogin.local.xcconfig`

These files wire the Kakao scheme and iOS callback URL schemes into the native projects.

If you need a one-off local smoke build before the release keystore is ready, add `-AllowDebugSigning`. The validator now blocks production Android builds without a real keystore by default.

## 5. Platform Console Checks

- Google: package/bundle identifiers and SHA values registered
- Kakao: Android key hash, package name, iOS bundle id, URL scheme registered
- Apple: `Sign in with Apple` capability, Service ID, redirect URI registered
- Android: verify that `android/key.properties` points to the real upload keystore

## 6. Final QA

- Confirm login, sign-up, sign-out, session restore
- Confirm saved timetables persist after app relaunch
- Confirm server-backed mode appears on auth screens
- Confirm the app is not pointing to localhost
- Confirm the selected release target is enabled in Flutter (`web/` exists for web builds)
