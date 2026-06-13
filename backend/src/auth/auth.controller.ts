import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  Res,
} from '@nestjs/common';

import { AuthService } from './auth.service';
import { PasswordResetDto } from './dto/password-reset.dto';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';
import { SocialSignInDto } from './dto/social-sign-in.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  signUp(@Body() body: SignUpDto) {
    return this.authService.signUp(body);
  }

  @Post('signin')
  @HttpCode(HttpStatus.OK)
  signIn(@Body() body: SignInDto) {
    return this.authService.signIn(body);
  }

  @Post('social-signin')
  @HttpCode(HttpStatus.OK)
  signInWithProvider(@Body() body: SocialSignInDto) {
    return this.authService.signInWithProvider(body);
  }

  @Post('apple/callback')
  appleCallback(
    @Body() body: Record<string, unknown>,
    @Res() response: { redirect: (url: string) => void },
  ) {
    response.redirect(this.buildAppleAndroidRedirectUrl(body));
  }

  @Post('password-reset')
  @HttpCode(HttpStatus.OK)
  requestPasswordReset(@Body() body: PasswordResetDto) {
    return this.authService.requestPasswordReset(body);
  }

  @Post('signout')
  @HttpCode(HttpStatus.OK)
  signOut(@Headers('authorization') authorization?: string) {
    return this.authService.signOut(authorization);
  }

  @Get('me')
  me(@Headers('authorization') authorization?: string) {
    return this.authService.getCurrentUser(authorization);
  }

  @Patch('me')
  updateProfile(
    @Headers('authorization') authorization: string | undefined,
    @Body() body: UpdateProfileDto,
  ) {
    return this.authService.updateCurrentUser(authorization, body);
  }

  private buildAppleAndroidRedirectUrl(body: Record<string, unknown>) {
    const query = new URLSearchParams();
    const allowedKeys = ['code', 'id_token', 'state', 'user', 'error'];

    for (const key of allowedKeys) {
      const value = body[key];
      if (typeof value === 'string' && value.trim().length > 0) {
        query.set(key, value);
      }
    }

    const packageId =
      process.env.APPLE_ANDROID_PACKAGE_ID?.trim() || 'com.maiyard.class_finder';
    const queryString = query.toString();
    const callbackPath = queryString.length > 0 ? `?${queryString}` : '';

    return `intent://callback${callbackPath}#Intent;package=${packageId};scheme=signinwithapple;end`;
  }
}
