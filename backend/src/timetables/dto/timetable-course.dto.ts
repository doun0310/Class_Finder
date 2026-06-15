import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import {
  courseCategoryValues,
  CourseCategoryValue,
  ratingSourceValues,
  RatingSourceValue,
} from '../timetable.constants';
import { TimetableSlotDto } from './timetable-slot.dto';

export class TimetableCourseDto {
  @IsString()
  @MaxLength(80)
  id!: string;

  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(80)
  professor!: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(6)
  credit!: number;

  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(5)
  rating!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(5)
  difficulty!: number;

  @IsBoolean()
  hasTeamProject!: boolean;

  @IsBoolean()
  isMajorRequired!: boolean;

  @IsIn(courseCategoryValues)
  category!: CourseCategoryValue;

  @IsIn(ratingSourceValues)
  ratingSource!: RatingSourceValue;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(6)
  grade!: number;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(8)
  @ValidateNested({ each: true })
  @Type(() => TimetableSlotDto)
  timeSlots!: TimetableSlotDto[];
}
