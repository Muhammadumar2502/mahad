import { DeviceType } from '@prisma/client';

export class DeviceResponseDto {
  id: number;
  student_id: number;
  device_name: string;
  device_type: DeviceType;
  device_identifier: string;
  ip_address?: string;
  user_agent?: string;
  is_active: boolean;
  is_blocked: boolean;
  last_active: Date;
  last_api_endpoint?: string;
  last_api_method?: string;
  app_version?: string;
  createdAt: Date;
  updatedAt: Date;
  user?: {
    name?: string;
    phone: string;
  };
}
