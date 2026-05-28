import { IsString, MaxLength } from 'class-validator';

export class RenameTimetableDto {
  @IsString()
  @MaxLength(80)
  name!: string;
}
