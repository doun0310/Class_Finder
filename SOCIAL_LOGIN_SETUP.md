# Social Login Setup

The project already includes runtime wiring for Google, Kakao, and Apple sign-in.
What is still required is provider console setup and the real release secrets.

## Current App Identifiers

- Android package: `com.maiyard.class_finder`
- iOS bundle id: `com.maiyard.classFinder`

## Dart Defines

Pass these values when you run or build the app:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_SERVER_CLIENT_ID \
  --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_GOOGLE_IOS_CLIENT_ID \
  --dart-define=KAKAO_NATIVE_APP_KEY=YOUR_KAKAO_NATIVE_APP_KEY \
  --dart-define=KAKAO_CUSTOM_SCHEME=kakaoYOUR_KAKAO_NATIVE_APP_KEY \
  --dart-define=APPLE_SERVICE_ID=YOUR_APPLE_SERVICE_ID \
  --dart-define=APPLE_REDIRECT_URI=https://api.example.com/auth/apple/callback
```

If you use `tool/configure_social_login.ps1` or `tool/build_release.ps1`, the project also generates:

- `android/social-login.properties`
- `ios/Flutter/SocialLogin.local.xcconfig`

The helper script derives the iOS Google reversed client id automatically from `GOOGLE_IOS_CLIENT_ID`.
If `KAKAO_CUSTOM_SCHEME` is empty, it derives the Kakao callback scheme as `kakao{NATIVE_APP_KEY}`.

## Google

- Create a Google Cloud or Firebase project
- Register the Android OAuth client for `com.maiyard.class_finder`
- Register the Android SHA-1 and SHA-256 values
- Register the iOS OAuth client for `com.maiyard.classFinder`
- Issue the iOS client id
- Issue the server or web client id if your backend verifies Google tokens

## Kakao

- Create a Kakao Developers app
- Issue the Native App Key
- Register `com.maiyard.class_finder` in the Android platform settings
- Register the Android key hash
- Register `com.maiyard.classFinder` in the iOS platform settings
- Enable Kakao Login
- Enable OpenID Connect if your backend requires it
- Register the callback URL scheme `kakao{NATIVE_APP_KEY}` or your custom scheme

## Apple

- Enroll in the Apple Developer Program
- Enable `Sign in with Apple` for the App ID
- Enable the same capability in the iOS target
- Create a Service ID if Apple login must also work outside native iOS
- Register the redirect URI
- Configure server-side token verification if you want backend-issued sessions

## Backend Payload

`RemoteAuthRepository` sends these fields to `/auth/social-signin`:

- `provider`
- `providerUserId`
- `email`
- `displayName`
- `idToken`
- `accessToken`
- `authorizationCode`

The backend should verify the provider token and then issue the app's own session or JWT.
