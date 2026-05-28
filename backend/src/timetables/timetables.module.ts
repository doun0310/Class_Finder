import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { TimetablesController } from './timetables.controller';
import { TimetablesService } from './timetables.service';

@Module({
  imports: [AuthModule],
  controllers: [TimetablesController],
  providers: [TimetablesService],
})
export class TimetablesModule {}
