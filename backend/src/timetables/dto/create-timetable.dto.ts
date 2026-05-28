import { Type } from 'class-transformer';
import {
  IsArray,
  IsNumber,
  IsObject,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

import { TimetableCourseDto } from './timetable-course.dto';

export class CreateTimetableDto {
  @IsString()
  @MaxLength(80)
  name!: string;

  @Type(() => Number)
  @IsNumber()
  score!: number;

  @IsObject()
  scoreBreakdown!: Record<string, number>;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TimetableCourseDto)
  courses!: TimetableCourseDto[];
}
