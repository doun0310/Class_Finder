import { Type } from 'class-transformer';
import { IsInt, IsString } from 'class-validator';

export class TimetableSlotDto {
  @IsString()
  day!: string;

  @Type(() => Number)
  @IsInt()
  startHour!: number;

  @Type(() => Number)
  @IsInt()
  endHour!: number;
}
