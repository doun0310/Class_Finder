import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsNumber,
  IsObject,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { TimetableCourseDto } from './timetable-course.dto';

export class CreateTimetableDto {
  @IsString()
  @MaxLength(80)
  name!: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  score!: number;

  @IsObject()
  scoreBreakdown!: Record<string, number>;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => TimetableCourseDto)
  courses!: TimetableCourseDto[];
}
