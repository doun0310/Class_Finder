import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  UnauthorizedException,
} from '@nestjs/common';

import { AuthService } from '../auth/auth.service';
import { CreateTimetableDto } from './dto/create-timetable.dto';
import { RenameTimetableDto } from './dto/rename-timetable.dto';
import { TimetablesService } from './timetables.service';

@Controller('users/:userId/timetables')
export class TimetablesController {
  constructor(
    private readonly timetablesService: TimetablesService,
    private readonly authService: AuthService,
  ) {}

  @Get()
  async list(
    @Param('userId') userId: string,
    @Headers('authorization') authorization?: string,
  ) {
    await this.assertOwnership(authorization, userId);
    const timetables = await this.timetablesService.listByUser(userId);
    return { timetables };
  }

  @Post()
  async create(
    @Param('userId') userId: string,
    @Headers('authorization') authorization: string | undefined,
    @Body() body: CreateTimetableDto,
  ) {
    await this.assertOwnership(authorization, userId);
    const timetable = await this.timetablesService.create(userId, body);
    return { timetable };
  }

  @Patch(':id')
  async rename(
    @Param('userId') userId: string,
    @Param('id') id: string,
    @Headers('authorization') authorization: string | undefined,
    @Body() body: RenameTimetableDto,
  ) {
    await this.assertOwnership(authorization, userId);
    const timetable = await this.timetablesService.rename(userId, id, body);
    return { timetable };
  }

  @Delete(':id')
  async delete(
    @Param('userId') userId: string,
    @Param('id') id: string,
    @Headers('authorization') authorization?: string,
  ) {
    await this.assertOwnership(authorization, userId);
    await this.timetablesService.delete(userId, id);
    return { ok: true };
  }

  private async assertOwnership(
    authorization: string | undefined,
    userId: string,
  ) {
    const user = await this.authService.authenticate(authorization);
    if (user.id !== userId) {
      throw new UnauthorizedException(
        'You can only access your own timetables.',
      );
    }
  }
}
