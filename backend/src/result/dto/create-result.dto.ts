import {
  IsArray,
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

export class CreateResultDto {
  @IsString()
  @IsOptional()
  type: null | undefined | 'RANDOM' | 'SPECIAL';

  @IsNotEmpty()
  @IsNumber()
  solved: number;

  @IsOptional()
  @IsNumber()
  test_id: number;

  @IsOptional()
  @IsNumber()
  special_test_id: number;

  @IsArray()
  @IsNotEmpty()
  answers = [];

  @IsOptional()
  @IsString()
  startTime?: string;

  @IsOptional()
  @IsString()
  finishTime?: string;
}
