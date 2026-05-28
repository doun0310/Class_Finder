import { Body, Controller, Get, Headers, Patch, Post } from '@nestjs/common';

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
  signIn(@Body() body: SignInDto) {
    return this.authService.signIn(body);
  }

  @Post('social-signin')
  signInWithProvider(@Body() body: SocialSignInDto) {
    return this.authService.signInWithProvider(body);
  }

  @Post('password-reset')
  requestPasswordReset(@Body() body: PasswordResetDto) {
    return this.authService.requestPasswordReset(body);
  }

  @Post('signout')
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
}
