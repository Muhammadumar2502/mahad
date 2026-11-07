// import { IsBoolean, IsEmail, IsInt, IsNotEmpty, IsOptional, IsString, Min, MinLength } from 'class-validator';

// export class CreateGroupDto {
//     @IsNotEmpty()
//     @IsString()
//     name: string;

//   @IsOptional()
//   @IsBoolean()
//   hasTime?: boolean = false;

//   @IsOptional()
//   @IsInt()
//   timeMinutes?: number = 0;

//   @IsOptional()
//   @IsInt()
//   fullTime?: number = 0;
// }

import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Validate,
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

@ValidatorConstraint({ name: 'TimeValidator', async: false })
export class TimeValidator implements ValidatorConstraintInterface {
  validate(_: any, args: ValidationArguments) {
    const obj = args.object as any;

    // Agar hasTime false bo‘lsa -> ikkala qiymatni 0 ga o‘zgartiramiz
    if (obj.hasTime === false) {
      obj.timeMinutes = 0;
      obj.fullTime = 0;
      return true;
    }

    // Agar hasTime true bo‘lsa -> faqat bittasi 0 dan farqli bo‘lishi kerak
    if (obj.hasTime === true) {
      const hasTimeMinutes = obj.timeMinutes && obj.timeMinutes > 0;
      const hasFullTime = obj.fullTime && obj.fullTime > 0;
      return hasTimeMinutes !== hasFullTime;
    }

    // hasTime undefined bo‘lsa ham o'tkazamiz
    return true;
  }

  defaultMessage(_: ValidationArguments) {
    return `Agar hasTime true bo'lsa, timeMinutes yoki fullTime dan faqat bittasi 0 dan farqli bo'lishi kerak.`;
  }
}

export class CreateGroupDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsOptional()
  @IsBoolean()
  hasTime?: boolean = false;

  @IsOptional()
  @IsInt()
  timeMinutes?: number = 0;

  @IsOptional()
  @IsInt()
  fullTime?: number = 0;

  @IsOptional()
  @IsBoolean()
  forceNextQuestion?: boolean = false;

  @Validate(TimeValidator)
  customValidation?: boolean;
}
