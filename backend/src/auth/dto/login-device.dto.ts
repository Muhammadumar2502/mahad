import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { DeviceType } from '@prisma/client';

export class LoginDeviceDto {
  @IsNotEmpty()
  @IsString()
  device_name: string;

  @IsNotEmpty()
  @IsEnum(DeviceType)
  device_type: DeviceType;

  @IsNotEmpty()
  @IsString()
  device_identifier: string;

  @IsOptional()
  @IsString()
  user_agent?: string;

  @IsOptional()
  @IsString()
  app_version?: string;
}
