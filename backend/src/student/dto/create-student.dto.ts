import {
  IsEmail,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Length,
  Min,
  MinLength,
} from 'class-validator';

export class CreateStudentDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(4)
  name: string;

  @IsNotEmpty()
  @IsString()
  @IsPhoneNumber('UZ')
  @Length(13)
  phone: string;

  @IsNotEmpty()
  @IsNumber()
  group_id: number;

  @IsOptional()
  @IsString()
  @MinLength(6, { message: "Parol kamida 6 ta belgidan iborat bo'lishi kerak" })
  password?: string;
}
