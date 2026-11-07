import {
  IsEmail,
  IsNotEmpty,
  IsNumber,
  isNumber,
  IsNumberString,
  isNumberString,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';

export class CreateTestDto {
  @IsOptional()
  @IsString()
  name?: string;
}
