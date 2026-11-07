import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { Role } from '@prisma/client';
import { DeviceResponseDto } from './dto/device-response.dto';

@Injectable()
export class DeviceService {
  constructor(private prisma: PrismaClientService) {}

  async getMyDevice(userId: number, role: Role): Promise<DeviceResponseDto> {
    if (role !== Role.STUDENT) {
      throw new NotFoundException('Faqat studentlar qurilma boshqarishi mumkin');
    }

    const device = await this.prisma.device.findFirst({
      where: {
        student_id: userId,
        is_active: true,
      },
    });

    if (!device) {
      throw new NotFoundException('Faol qurilma topilmadi');
    }

    return device;
  }

  async getAllDevices(params: {
    role?: Role;
    is_active?: boolean;
    search?: string;
  }) {
    const { is_active, search } = params;

    const where: any = {};

    if (is_active !== undefined) {
      where.is_active = is_active;
    }

    // Get all devices (no pagination) - all devices belong to students
    const devices = await this.prisma.device.findMany({
      where,
      include: {
        student: {
          select: { 
            id: true, 
            name: true, 
            phone: true,
            group: {
              select: {
                id: true,
                name: true,
              }
            }
          },
        },
      },
      orderBy: { last_active: 'desc' },
    });

    // Apply search filter and format
    const devicesWithUsers = devices.map((device) => {
      const user = device.student;

      // Apply search filter
      if (search && user) {
        const searchLower = search.toLowerCase();
        const matchesName = user.name?.toLowerCase().includes(searchLower);
        const matchesPhone = user.phone?.toLowerCase().includes(searchLower);

        if (!matchesName && !matchesPhone) {
          return null;
        }
      }

      const { student, ...deviceData } = device;
      return {
        ...deviceData,
        user,
      };
    });

    // Filter out null values (devices that didn't match search)
    const filteredDevices = devicesWithUsers.filter((d) => d !== null);

    return {
      devices: filteredDevices,
      total: filteredDevices.length,
    };
  }

  async getUserDevices(userId: number, role: Role) {
    if (role !== Role.STUDENT) {
      throw new NotFoundException('Faqat studentlar qurilma boshqarishi mumkin');
    }

    const devices = await this.prisma.device.findMany({
      where: {
        student_id: userId,
      },
      orderBy: { last_active: 'desc' },
    });

    return devices;
  }

  async deactivateDevice(deviceId: number) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Qurilma topilmadi');
    }

    return await this.prisma.device.update({
      where: { id: deviceId },
      data: { is_active: false },
    });
  }

  async activateDevice(deviceId: number) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Qurilma topilmadi');
    }

    // Deactivate all other devices for this student
    await this.prisma.device.updateMany({
      where: {
        student_id: device.student_id,
        id: { not: deviceId },
      },
      data: { is_active: false },
    });

    // Activate the selected device
    return await this.prisma.device.update({
      where: { id: deviceId },
      data: { is_active: true },
    });
  }

  async deleteDevice(deviceId: number) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Qurilma topilmadi');
    }

    return await this.prisma.device.delete({
      where: { id: deviceId },
    });
  }

  async blockDevice(deviceId: number) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Qurilma topilmadi');
    }

    return await this.prisma.device.update({
      where: { id: deviceId },
      data: { is_blocked: true },
    });
  }

  async unblockDevice(deviceId: number) {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });

    if (!device) {
      throw new NotFoundException('Qurilma topilmadi');
    }

    return await this.prisma.device.update({
      where: { id: deviceId },
      data: { is_blocked: false },
    });
  }
}
