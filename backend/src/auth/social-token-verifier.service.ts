import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createPublicKey, createVerify, type JsonWebKey } from 'node:crypto';

import { SocialSignInDto } from './dto/social-sign-in.dto';

type SocialProvider = SocialSignInDto['provider'];

export interface VerifiedSocialIdentity {
  provider: SocialProvider;
  providerUserId: string;
  email?: string;
  displayName?: string;
}

interface GoogleTokenInfo {
  sub?: string;
  email?: string;
  email_verified?: boolean | string;
  name?: string;
  aud?: string;
}

interface KakaoUserInfo {
  id?: number | string;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
    };
  };
  properties?: {
    nickname?: string;
  };
}

interface AppleJwkSet {
  keys?: Record<string, unknown>[];
}

interface JwtHeader {
  alg?: string;
  kid?: string;
}

interface AppleJwtPayload {
  sub?: string;
  email?: string;
  aud?: string | string[];
  iss?: string;
  exp?: number;
}

@Injectable()
export class SocialTokenVerifier {
  private appleKeys: Record<string, unknown>[] = [];
  private appleKeysExpiresAt = 0;

  async verify(input: SocialSignInDto): Promise<VerifiedSocialIdentity> {
    switch (input.provider) {
      case 'google':
        return this.verifyGoogle(input);
      case 'kakao':
        return this.verifyKakao(input);
      case 'apple':
        return this.verifyApple(input);
    }
  }

  private async verifyGoogle(
    input: SocialSignInDto,
  ): Promise<VerifiedSocialIdentity> {
    const idToken = this.requireText(input.idToken, 'Google ID token is required.');
    const response = await this.fetchProvider(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(
        idToken,
      )}`,
    );
    const data = await this.parseProviderResponse<GoogleTokenInfo>(
      response,
      'Google token verification failed.',
    );

    const providerUserId = data.sub?.trim();
    if (!providerUserId) {
      throw new UnauthorizedException('Google token is missing a subject.');
    }

    this.ensureAllowedAudience(data.aud, this.googleAudiences(), 'Google');

    const emailVerified =
      data.email_verified === true || data.email_verified === 'true';

    return {
      provider: 'google',
      providerUserId,
      email: emailVerified ? this.normalizeEmail(data.email) : undefined,
      displayName: this.trimOrUndefined(data.name),
    };
  }

  private async verifyKakao(
    input: SocialSignInDto,
  ): Promise<VerifiedSocialIdentity> {
    const accessToken = this.requireText(
      input.accessToken,
      'Kakao access token is required.',
    );
    const response = await this.fetchProvider(
      'https://kapi.kakao.com/v2/user/me',
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      },
    );
    const data = await this.parseProviderResponse<KakaoUserInfo>(
      response,
      'Kakao token verification failed.',
    );
    const providerUserId = data.id?.toString().trim();

    if (!providerUserId) {
      throw new UnauthorizedException('Kakao token is missing a subject.');
    }

    return {
      provider: 'kakao',
      providerUserId,
      email: this.normalizeEmail(data.kakao_account?.email),
      displayName: this.trimOrUndefined(
        data.kakao_account?.profile?.nickname ?? data.properties?.nickname,
      ),
    };
  }

  private async verifyApple(
    input: SocialSignInDto,
  ): Promise<VerifiedSocialIdentity> {
    const idToken = this.requireText(input.idToken, 'Apple ID token is required.');
    const decoded = this.decodeJwt<AppleJwtPayload>(idToken);

    const kid = decoded.header.kid?.trim();
    if (decoded.header.alg !== 'RS256' || !kid) {
      throw new UnauthorizedException('Apple token has an unsupported header.');
    }
    if (decoded.payload.iss !== 'https://appleid.apple.com') {
      throw new UnauthorizedException('Apple token issuer is invalid.');
    }
    const providerUserId = decoded.payload.sub?.trim();
    if (!providerUserId) {
      throw new UnauthorizedException('Apple token is missing a subject.');
    }
    if (
      typeof decoded.payload.exp !== 'number' ||
      decoded.payload.exp * 1000 <= Date.now()
    ) {
      throw new UnauthorizedException('Apple token has expired.');
    }

    this.ensureAllowedAudience(decoded.payload.aud, this.appleAudiences(), 'Apple');

    const key = await this.getAppleSigningKey(kid);
    const verifier = createVerify('RSA-SHA256');
    verifier.update(decoded.signingInput);
    verifier.end();

    const verified = verifier.verify(
      createPublicKey({ key: key as JsonWebKey, format: 'jwk' }),
      decoded.signature,
    );

    if (!verified) {
      throw new UnauthorizedException('Apple token signature is invalid.');
    }

    return {
      provider: 'apple',
      providerUserId,
      email: this.normalizeEmail(decoded.payload.email),
      displayName: this.trimOrUndefined(input.displayName),
    };
  }

  private async parseProviderResponse<T>(response: Response, message: string) {
    if (!response.ok) {
      throw new UnauthorizedException(message);
    }

    try {
      return (await response.json()) as T;
    } catch {
      throw new UnauthorizedException(message);
    }
  }

  private async fetchProvider(url: string, init?: RequestInit) {
    const timeoutMs = this.providerTimeoutMs();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      return await fetch(url, {
        ...init,
        signal: controller.signal,
      });
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new UnauthorizedException('Provider token verification timed out.');
      }
      throw new UnauthorizedException('Provider token verification failed.');
    } finally {
      clearTimeout(timeout);
    }
  }

  private providerTimeoutMs() {
    const raw = Number(process.env.SOCIAL_PROVIDER_TIMEOUT_MS ?? '5000');
    return Number.isFinite(raw) && raw > 0 ? raw : 5000;
  }

  private decodeJwt<TPayload>(token: string) {
    const [encodedHeader, encodedPayload, encodedSignature] = token.split('.');
    if (!encodedHeader || !encodedPayload || !encodedSignature) {
      throw new UnauthorizedException('Provider token is malformed.');
    }

    try {
      return {
        header: JSON.parse(
          Buffer.from(encodedHeader, 'base64url').toString('utf8'),
        ) as JwtHeader,
        payload: JSON.parse(
          Buffer.from(encodedPayload, 'base64url').toString('utf8'),
        ) as TPayload,
        signingInput: `${encodedHeader}.${encodedPayload}`,
        signature: Buffer.from(encodedSignature, 'base64url'),
      };
    } catch {
      throw new UnauthorizedException('Provider token is malformed.');
    }
  }

  private async getAppleSigningKey(kid: string) {
    if (this.appleKeys.length === 0 || this.appleKeysExpiresAt <= Date.now()) {
      const response = await this.fetchProvider(
        'https://appleid.apple.com/auth/keys',
      );
      const data = await this.parseProviderResponse<AppleJwkSet>(
        response,
        'Apple signing keys could not be loaded.',
      );
      this.appleKeys = data.keys ?? [];
      this.appleKeysExpiresAt = Date.now() + 1000 * 60 * 60;
    }

    const key = this.appleKeys.find((candidate) => candidate.kid === kid);
    if (!key) {
      throw new UnauthorizedException('Apple signing key was not found.');
    }
    return key;
  }

  private ensureAllowedAudience(
    aud: string | string[] | undefined,
    allowedAudiences: string[],
    provider: string,
  ) {
    if (allowedAudiences.length === 0) {
      if (process.env.NODE_ENV === 'production') {
        throw new UnauthorizedException(
          `${provider} token audience configuration is required.`,
        );
      }
      return;
    }

    const audiences = Array.isArray(aud) ? aud : aud ? [aud] : [];
    if (!audiences.some((value) => allowedAudiences.includes(value))) {
      throw new UnauthorizedException(`${provider} token audience is invalid.`);
    }
  }

  private googleAudiences() {
    return this.envList(
      'GOOGLE_CLIENT_IDS',
      'GOOGLE_SERVER_CLIENT_ID',
      'GOOGLE_IOS_CLIENT_ID',
    );
  }

  private appleAudiences() {
    return this.envList(
      'APPLE_AUDIENCES',
      'APPLE_SERVICE_ID',
      'APPLE_BUNDLE_ID',
    );
  }

  private envList(...keys: string[]) {
    return keys
      .flatMap((key) => (process.env[key] ?? '').split(','))
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
  }

  private requireText(value: string | undefined, message: string) {
    const trimmed = value?.trim();
    if (!trimmed) {
      throw new UnauthorizedException(message);
    }
    return trimmed;
  }

  private normalizeEmail(value: string | undefined) {
    const trimmed = this.trimOrUndefined(value);
    return trimmed?.toLowerCase();
  }

  private trimOrUndefined(value: string | undefined) {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : undefined;
  }
}
