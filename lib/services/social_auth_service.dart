import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_repository.dart';

abstract class SocialAuthGateway {
  Future<SocialAuthPayload> authenticate(AuthProvider provider);
}

class DeviceSocialAuthService implements SocialAuthGateway {
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const _kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const _kakaoCustomScheme = String.fromEnvironment(
    'KAKAO_CUSTOM_SCHEME',
  );
  static const _appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
  static const _appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  bool _googleInitialized = false;
  bool _kakaoInitialized = false;

  @override
  Future<SocialAuthPayload> authenticate(AuthProvider provider) {
    return switch (provider) {
      AuthProvider.google => _authenticateWithGoogle(),
      AuthProvider.kakao => _authenticateWithKakao(),
      AuthProvider.apple => _authenticateWithApple(),
    };
  }

  Future<SocialAuthPayload> _authenticateWithGoogle() async {
    if (!_looksConfiguredForGoogle()) {
      throw const AuthException(
        AuthErrorCode.socialUnavailable,
        'Google 로그인 설정이 없습니다. '
        '`GOOGLE_SERVER_CLIENT_ID`를 추가하고, '
        'Android는 Google Cloud 또는 Firebase에 패키지명과 SHA-1/SHA-256을 등록해야 합니다. '
        'iOS는 `GOOGLE_IOS_CLIENT_ID`와 reversed client id URL scheme이 필요합니다.',
      );
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      );
      _googleInitialized = true;
    }

    GoogleSignInAccount account;
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      account = await GoogleSignIn.instance.authenticate();
    } else {
      final recovered = await GoogleSignIn.instance
          .attemptLightweightAuthentication(reportAllExceptions: true);
      if (recovered == null) {
        throw const AuthException(
          AuthErrorCode.socialUnavailable,
          '현재 플랫폼에서는 Google 로그인 대화형 인증을 바로 시작할 수 없습니다.',
        );
      }
      account = recovered;
    }

    final authentication = account.authentication;
    if ((authentication.idToken ?? '').isEmpty) {
      throw const AuthException(
        AuthErrorCode.socialUnavailable,
        'Google ID 토큰을 받지 못했습니다. 서버와 OAuth 설정을 다시 확인해 주세요.',
      );
    }

    return SocialAuthPayload(
      provider: AuthProvider.google,
      providerUserId: account.id,
      email: account.email,
      displayName: account.displayName,
      idToken: authentication.idToken,
    );
  }

  Future<SocialAuthPayload> _authenticateWithKakao() async {
    if (_kakaoNativeAppKey.isEmpty) {
      throw const AuthException(
        AuthErrorCode.socialUnavailable,
        'Kakao Native App Key가 없습니다. '
        '`KAKAO_NATIVE_APP_KEY`를 추가하고 Android 패키지명 '
        '`com.maiyard.class_finder`, iOS 번들 ID `com.maiyard.classFinder`를 '
        'Kakao Developers 콘솔에 등록해야 합니다.',
      );
    }

    if (!_kakaoInitialized) {
      KakaoSdk.init(
        nativeAppKey: _kakaoNativeAppKey,
        customScheme: _kakaoCustomScheme.isEmpty ? null : _kakaoCustomScheme,
      );
      _kakaoInitialized = true;
    }

    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final user = await UserApi.instance.me();
    return SocialAuthPayload(
      provider: AuthProvider.kakao,
      providerUserId: user.id.toString(),
      email: user.kakaoAccount?.email,
      displayName: user.kakaoAccount?.profile?.nickname,
      idToken: token.idToken,
      accessToken: token.accessToken,
    );
  }

  Future<SocialAuthPayload> _authenticateWithApple() async {
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw const AuthException(
        AuthErrorCode.socialUnavailable,
        '이 기기에서는 Apple 로그인을 사용할 수 없습니다.',
      );
    }

    final requiresWebOptions =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
    if (requiresWebOptions &&
        (_appleServiceId.isEmpty || _appleRedirectUri.isEmpty)) {
      throw const AuthException(
        AuthErrorCode.socialUnavailable,
        'Android에서 Apple 로그인을 사용하려면 '
        '`APPLE_SERVICE_ID`와 `APPLE_REDIRECT_URI`가 필요합니다.',
      );
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email],
      webAuthenticationOptions: requiresWebOptions
          ? WebAuthenticationOptions(
              clientId: _appleServiceId,
              redirectUri: Uri.parse(_appleRedirectUri),
            )
          : null,
    );

    final fullName = [
      credential.givenName?.trim(),
      credential.familyName?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

    return SocialAuthPayload(
      provider: AuthProvider.apple,
      providerUserId: credential.userIdentifier,
      email: credential.email,
      displayName: fullName.isEmpty ? null : fullName,
      idToken: credential.identityToken,
      authorizationCode: credential.authorizationCode,
    );
  }

  bool _looksConfiguredForGoogle() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _googleIosClientId.isNotEmpty || _googleServerClientId.isNotEmpty;
    }

    return _googleServerClientId.isNotEmpty;
  }
}
