import {
  Body,
  Controller,
  Headers,
  Post,
  UnauthorizedException,
} from '@nestjs/common';

import { AuthService } from '../auth/auth.service';
import { SyncUserDto } from './dto/sync-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly authService: AuthService,
  ) {}

  @Post('sync')
  async sync(
    @Body() body: SyncUserDto,
    @Headers('authorization') authorization?: string,
  ) {
    const authenticatedUser = await this.authService.authenticate(authorization);
    if (authenticatedUser.id !== body.id) {
      throw new UnauthorizedException('You can only sync your own profile.');
    }

    const syncedUser = await this.usersService.sync(body);
    return { user: syncedUser };
  }
}
