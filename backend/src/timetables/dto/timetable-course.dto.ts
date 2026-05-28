import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsString,
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
  id!: string;

  @IsString()
  name!: string;

  @IsString()
  professor!: string;

  @Type(() => Number)
  @IsInt()
  credit!: number;

  @Type(() => Number)
  @IsNumber()
  rating!: number;

  @Type(() => Number)
  @IsInt()
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
  grade!: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TimetableSlotDto)
  timeSlots!: TimetableSlotDto[];
}
