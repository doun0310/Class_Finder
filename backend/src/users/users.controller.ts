import { Body, Controller, Post } from '@nestjs/common';

import { SyncUserDto } from './dto/sync-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('sync')
  async sync(@Body() body: SyncUserDto) {
    const user = await this.usersService.sync(body);
    return { user };
  }
}
