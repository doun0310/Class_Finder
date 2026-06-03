import { Module } from '@nestjs/common';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SocialTokenVerifier } from './social-token-verifier.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService, SocialTokenVerifier],
  exports: [AuthService],
})
export class AuthModule {}
