import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { User } from '@prisma/client';
import {
  createHash,
  randomBytes,
  randomUUID,
  scryptSync,
  timingSafeEqual,
} from 'node:crypto';

import { PrismaService } from '../prisma/prisma.service';
import { PasswordResetDto } from './dto/password-reset.dto';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';
import { SocialSignInDto } from './dto/social-sign-in.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

const sessionLifetimeMs = 1000 * 60 * 60 * 24 * 30;
const loginLockMs = 1000 * 30;
const maxFailedLoginCount = 5;

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async signUp(input: SignUpDto) {
    const email = input.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existing) {
      throw new ConflictException('Email is already in use.');
    }

    if (input.password.trim().length < 6) {
      throw new BadRequestException('Password must be at least 6 characters.');
    }

    const salt = this.randomToken(16);
    const user = await this.prisma.user.create({
      data: {
        id: randomUUID(),
        email,
        name: input.name.trim(),
        studentId: input.studentId.trim(),
        department: input.department.trim(),
        grade: input.grade,
        passwordSalt: salt,
        passwordHash: this.hashPassword(input.password, salt),
      },
    });

    const token = await this.createSession(user.id);
    return this.buildAuthResponse(user, token);
  }

  async signIn(input: SignInDto) {
    const email = input.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user || !user.passwordHash || !user.passwordSalt) {
      throw new NotFoundException('User not found.');
    }

    this.ensureUserUnlocked(user);

    const isValidPassword = this.verifyPassword(
      input.password,
      user.passwordSalt,
      user.passwordHash,
    );

    if (!isValidPassword) {
      const failedLoginCount = user.failedLoginCount + 1;

      if (failedLoginCount >= maxFailedLoginCount) {
        await this.prisma.user.update({
          where: { id: user.id },
          data: {
            failedLoginCount: 0,
            lockedUntil: new Date(Date.now() + loginLockMs),
          },
        });
        throw new HttpException(
          'Too many login attempts.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          failedLoginCount,
        },
      });
      throw new UnauthorizedException('Wrong password.');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        failedLoginCount: 0,
        lockedUntil: null,
      },
    });

    const token = await this.createSession(user.id);
    return this.buildAuthResponse(user, token);
  }

  async signInWithProvider(input: SocialSignInDto) {
    const normalizedEmail = input.email?.trim().toLowerCase();
    const providerUserId = input.providerUserId?.trim();
    const seedEmail =
      normalizedEmail ??
      `${input.provider}.${(providerUserId?.length ?? 0) > 0 ? providerUserId : 'user'}@classfinder.app`;

    let user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: seedEmail },
          {
            socialProvider: input.provider,
            providerUserId,
          },
        ],
      },
    });

    const nextDisplayName = this.hasText(input.displayName)
      ? input.displayName!.trim()
      : `${this.capitalize(input.provider)} User`;

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          id: randomUUID(),
          email: seedEmail,
          name: nextDisplayName,
          studentId: '20240000',
          department: 'Computer Science',
          grade: 2,
          socialProvider: input.provider,
          providerUserId,
        },
      });
    } else if (
      user.socialProvider !== input.provider ||
      user.providerUserId !== providerUserId ||
      user.name !== nextDisplayName
    ) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          socialProvider: input.provider,
          providerUserId,
          name: nextDisplayName,
        },
      });
    }

    const token = await this.createSession(user.id);
    return this.buildAuthResponse(user, token);
  }

  async requestPasswordReset(_: PasswordResetDto) {
    return {
      message:
          'If the email exists, password reset instructions have been sent.',
    };
  }

  async signOut(authorization: string | undefined) {
    const token = this.extractBearerToken(authorization);
    const tokenHash = this.hashToken(token);

    await this.prisma.authSession.updateMany({
      where: {
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });

    return { ok: true };
  }

  async getCurrentUser(authorization: string | undefined) {
    const user = await this.authenticate(authorization);
    return { user: this.serializeUser(user) };
  }

  async updateCurrentUser(
    authorization: string | undefined,
    input: UpdateProfileDto,
  ) {
    const user = await this.authenticate(authorization);
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: {
        name: input.name ?? user.name,
        studentId: input.studentId ?? user.studentId,
        department: input.department ?? user.department,
        grade: input.grade ?? user.grade,
      },
    });

    return { user: this.serializeUser(updated) };
  }

  async authenticate(authorization: string | undefined) {
    const token = this.extractBearerToken(authorization);
    const tokenHash = this.hashToken(token);

    const session = await this.prisma.authSession.findFirst({
      where: {
        tokenHash,
        revokedAt: null,
        expiresAt: {
          gt: new Date(),
        },
      },
      include: {
        user: true,
      },
    });

    if (!session) {
      throw new UnauthorizedException('Session is invalid.');
    }

    return session.user;
  }

  private ensureUserUnlocked(user: User) {
    if (user.lockedUntil && user.lockedUntil.getTime() > Date.now()) {
      throw new HttpException(
        'Too many login attempts.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async createSession(userId: string) {
    const token = this.randomToken(32);

    await this.prisma.authSession.create({
      data: {
        userId,
        tokenHash: this.hashToken(token),
        expiresAt: new Date(Date.now() + sessionLifetimeMs),
      },
    });

    return token;
  }

  private buildAuthResponse(user: User, token: string) {
    return {
      token,
      user: this.serializeUser(user),
    };
  }

  private serializeUser(user: User) {
    return {
      id: user.id,
      email: user.email ?? '',
      name: user.name ?? '',
      studentId: user.studentId ?? '',
      department: user.department ?? '',
      grade: user.grade ?? 1,
      createdAt: user.createdAt.toISOString(),
    };
  }

  private extractBearerToken(authorization: string | undefined) {
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authorization token is required.');
    }

    return authorization.substring('Bearer '.length).trim();
  }

  private randomToken(size: number) {
    return randomBytes(size).toString('base64url');
  }

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private hashPassword(password: string, salt: string) {
    return scryptSync(password, salt, 64).toString('hex');
  }

  private verifyPassword(password: string, salt: string, expectedHash: string) {
    const actual = Buffer.from(this.hashPassword(password, salt), 'hex');
    const expected = Buffer.from(expectedHash, 'hex');
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }

  private capitalize(value: string) {
    if (value.length === 0) {
      return value;
    }

    return `${value[0].toUpperCase()}${value.substring(1)}`;
  }

  private hasText(value: string | undefined) {
    return value !== undefined && value.trim().length > 0;
  }
}
