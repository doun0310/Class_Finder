import { Type } from 'class-transformer';
import { IsEmail, IsInt, IsString, MinLength } from 'class-validator';

export class SignUpDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  @MinLength(1)
  name!: string;

  @IsString()
  @MinLength(1)
  studentId!: string;

  @IsString()
  @MinLength(1)
  department!: string;

  @Type(() => Number)
  @IsInt()
  grade!: number;
}
