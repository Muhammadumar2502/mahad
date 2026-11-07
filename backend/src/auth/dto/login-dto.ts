import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { LoginDeviceDto } from './login-device.dto';

export class LoginDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(13)
  login: string;

  @IsNotEmpty()
  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => LoginDeviceDto)
  device?: LoginDeviceDto;
}
