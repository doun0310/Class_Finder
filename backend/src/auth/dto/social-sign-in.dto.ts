import { IsIn, IsOptional, IsString } from 'class-validator';

export class SocialSignInDto {
  @IsIn(['google', 'kakao', 'apple'])
  provider!: 'google' | 'kakao' | 'apple';

  @IsOptional()
  @IsString()
  providerUserId?: string;

  @IsOptional()
  @IsString()
  email?: string;

  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @IsString()
  idToken?: string;

  @IsOptional()
  @IsString()
  accessToken?: string;

  @IsOptional()
  @IsString()
  authorizationCode?: string;
}
