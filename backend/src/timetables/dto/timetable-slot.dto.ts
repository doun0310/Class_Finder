import { Type } from 'class-transformer';
import { IsInt, IsString, Max, MaxLength, Min } from 'class-validator';

export class TimetableSlotDto {
  @IsString()
  @MaxLength(10)
  day!: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  startHour!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(24)
  endHour!: number;
}
