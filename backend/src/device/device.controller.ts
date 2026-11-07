import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Query,
  UseGuards,
  Req,
  ParseIntPipe,
} from '@nestjs/common';
import { DeviceService } from './device.service';
import { AuthGuard } from 'src/_guard/auth.guard';
import { AdminGuard } from 'src/_guard/admin.guard';
import { Role } from '@prisma/client';

@Controller('device')
export class DeviceController {
  constructor(private readonly deviceService: DeviceService) {}

  @Get('me')
  @UseGuards(AuthGuard)
  async getMyDevice(@Req() req: any) {
    const user = req.user;
    return await this.deviceService.getMyDevice(user.id, user.role);
  }

  @Get('all')
  @UseGuards(AdminGuard)
  async getAllDevices(
    @Query('role') role?: Role,
    @Query('is_active') is_active?: string,
    @Query('search') search?: string,
  ) {
    return await this.deviceService.getAllDevices({
      role,
      is_active:
        is_active === 'true' ? true : is_active === 'false' ? false : undefined,
      search,
    });
  }

  @Get('user/:userId/:role')
  @UseGuards(AdminGuard)
  async getUserDevices(
    @Param('userId', ParseIntPipe) userId: number,
    @Param('role') role: Role,
  ) {
    return await this.deviceService.getUserDevices(userId, role);
  }

  @Patch(':id/deactivate')
  @UseGuards(AdminGuard)
  async deactivateDevice(@Param('id', ParseIntPipe) id: number) {
    return await this.deviceService.deactivateDevice(id);
  }

  @Patch(':id/activate')
  @UseGuards(AdminGuard)
  async activateDevice(@Param('id', ParseIntPipe) id: number) {
    return await this.deviceService.activateDevice(id);
  }

  @Delete(':id')
  @UseGuards(AdminGuard)
  async deleteDevice(@Param('id', ParseIntPipe) id: number) {
    return await this.deviceService.deleteDevice(id);
  }

  @Patch(':id/block')
  @UseGuards(AdminGuard)
  async blockDevice(@Param('id', ParseIntPipe) id: number) {
    return await this.deviceService.blockDevice(id);
  }

  @Patch(':id/unblock')
  @UseGuards(AdminGuard)
  async unblockDevice(@Param('id', ParseIntPipe) id: number) {
    return await this.deviceService.unblockDevice(id);
  }
}
