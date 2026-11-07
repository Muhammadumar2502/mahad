import {
  IsBoolean,
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
import { Transform, Type } from 'class-transformer';

export class CreateBookDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  imgPath: string;

  @IsNotEmpty()
  @IsNumberString()
  subject_id: string;

  @IsOptional()
  @Type(() => String)
  @Transform(({ value }) => {
    console.log(
      '🔄 Transform fullBlock - value:',
      value,
      'type:',
      typeof value,
    );
    // Agar value yo'q bo'lsa, undefined qaytarish (database yangilanmaydi)
    if (value === undefined || value === null || value === '') {
      console.log('🔄 Transform fullBlock - undefined (skip update)');
      return undefined;
    }
    // Explicitly: '1' yoki 1 yoki true → true
    // Explicitly: '0' yoki 0 yoki false → false
    if (value === '0' || value === 0 || value === false) {
      console.log('🔄 Transform fullBlock - result: false');
      return false;
    }
    if (value === '1' || value === 1 || value === true) {
      console.log('🔄 Transform fullBlock - result: true');
      return true;
    }
    // Fallback: boshqa qiymatlar uchun false
    console.log('🔄 Transform fullBlock - fallback: false');
    return false;
  })
  fullBlock: boolean = false;

  @IsOptional()
  @Type(() => String)
  @Transform(({ value }) => {
    console.log(
      '🔄 Transform stepBlock - value:',
      value,
      'type:',
      typeof value,
    );
    // Agar value yo'q bo'lsa, undefined qaytarish (database yangilanmaydi)
    if (value === undefined || value === null || value === '') {
      console.log('🔄 Transform stepBlock - undefined (skip update)');
      return undefined;
    }
    // Explicitly: '1' yoki 1 yoki true → true
    // Explicitly: '0' yoki 0 yoki false → false
    if (value === '0' || value === 0 || value === false) {
      console.log('🔄 Transform stepBlock - result: false');
      return false;
    }
    if (value === '1' || value === 1 || value === true) {
      console.log('🔄 Transform stepBlock - result: true');
      return true;
    }
    // Fallback: boshqa qiymatlar uchun false
    console.log('🔄 Transform stepBlock - fallback: false');
    return false;
  })
  stepBlock: boolean = false;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Transform(({ value }) => (value ? parseInt(value) : 60))
  passingPercentage: number = 60;
}
