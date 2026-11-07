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

export class CreateSectionDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  imgPath?: string;

  @IsNotEmpty()
  @IsNumberString()
  book_id: string;
}
