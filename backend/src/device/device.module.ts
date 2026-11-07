import { Module } from '@nestjs/common';
import { DeviceController } from './device.controller';
import { DeviceService } from './device.service';
import { PrismaClientModule } from 'src/_prisma_client/prisma_client.module';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [PrismaClientModule, JwtModule],
  controllers: [DeviceController],
  providers: [DeviceService],
  exports: [DeviceService],
})
export class DeviceModule {}
