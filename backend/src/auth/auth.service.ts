import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  HttpException,
} from '@nestjs/common';
import { LoginDto } from './dto/login-dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import { RedisService } from 'src/_redis/redis.service';

@Injectable()
export class AuthService {
  constructor(
    @Inject() private prisma: PrismaClientService,
    private jwtService: JwtService,
    private redis: RedisService,
  ) {}
  private logger = new Logger('Auth service');

  async login(data: LoginDto, req: any) {
    this.logger.log('login');

    // Brute-force himoyasi: bitta raqamga 15 daqiqada 20 urinish.
    const allowed = await this.redis.allow(`login:${data.login}`, 20, 15 * 60);
    if (!allowed) {
      throw new HttpException(
        {
          statusCode: 429,
          message: "Juda ko'p urinish. 15 daqiqadan so'ng qayta urinib ko'ring",
          error: 'Too Many Requests',
        },
        429,
      );
    }

    type UserWithRole = {
      id: number;
      phone: string;
      password: string;
      role: Role;
      [key: string]: any;
    };
    const where = { phone: data.login, password: data.password };
    let user: UserWithRole | null = await this.prisma.student.findUnique({
      where,
    });

    if (!user) {
      user = await this.prisma.teacher.findUnique({
        where,
      });
    }
    if (!user) {
      user = await this.prisma.admin.findUnique({
        where,
      });
    }

    if (!user) {
      throw new NotFoundException('Incorrect Credentials');
    }

    // Only STUDENT role has device management
    if (user.role !== 'STUDENT') {
      const payload = { user_id: user.id, role: user.role };
      const { password: _p, ...safeUser } = user;
      return {
        user: safeUser,
        access_token: await this.jwtService.signAsync(payload),
      };
    }

    // Check if device info is provided for STUDENT (backward compatibility)
    if (!data.device || !data.device.device_identifier) {
      throw new HttpException(
        {
          statusCode: 426,
          message: 'Iltimos, ilovaning oxirgi versiyasini yuklab oling',
          error: 'Upgrade Required',
        },
        426, // Upgrade Required
      );
    }

    // Extract IP address from request
    const ipAddress =
      req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress;

    // Check if this device already exists for this student
    let device = await this.prisma.device.findFirst({
      where: {
        student_id: user.id,
        device_identifier: data.device.device_identifier,
      },
    });

    // If device exists and is blocked, prevent login
    if (device && device.is_blocked) {
      throw new HttpException(
        {
          statusCode: 403,
          message: "Qurilma bloklangan. Admin bilan bog'laning",
          error: 'Forbidden',
        },
        403,
      );
    }

    if (device) {
      // Device exists
      if (device.is_active) {
        // This device is already active, just update it
        device = await this.prisma.device.update({
          where: { id: device.id },
          data: {
            device_name: data.device.device_name,
            ip_address: ipAddress,
            user_agent: data.device.user_agent,
            app_version: data.device.app_version,
            last_active: new Date(),
          },
        });
      } else {
        // This device is inactive, check if there are other active devices
        const activeDeviceCount = await this.prisma.device.count({
          where: {
            student_id: user.id,
            is_active: true,
          },
        });

        if (activeDeviceCount > 0) {
          throw new HttpException(
            {
              statusCode: 403,
              message:
                "Boshqa qurilma faol. Avval uni o'chirib yoki chiqib ketishingiz kerak.",
              error: 'Forbidden',
            },
            403,
          );
        }

        // No active devices, can activate this one
        device = await this.prisma.device.update({
          where: { id: device.id },
          data: {
            device_name: data.device.device_name,
            ip_address: ipAddress,
            user_agent: data.device.user_agent,
            app_version: data.device.app_version,
            is_active: true,
            last_active: new Date(),
          },
        });
      }
    } else {
      // New device - check if there are active devices
      const activeDeviceCount = await this.prisma.device.count({
        where: {
          student_id: user.id,
          is_active: true,
        },
      });

      if (activeDeviceCount > 0 && !(await this.isLegacySameDevice(user.id, data))) {
        throw new HttpException(
          {
            statusCode: 403,
            message:
              "Boshqa qurilma faol. Avval uni o'chirib yoki chiqib ketishingiz kerak.",
            error: 'Forbidden',
          },
          403,
        );
      }

      // Faol qurilma yo'q. Device.student_id UNIQUE — eski (faol emas) yozuv bo'lsa,
      // yangi yozuv yaratib bo'lmaydi (P2002 -> 500). Shuning uchun upsert:
      const deviceData = {
        device_name: data.device.device_name,
        device_type: data.device.device_type,
        device_identifier: data.device.device_identifier,
        ip_address: ipAddress,
        user_agent: data.device.user_agent,
        app_version: data.device.app_version,
        is_active: true,
        is_blocked: false,
        last_active: new Date(),
      };
      const old = await this.prisma.device.findUnique({ where: { student_id: user.id } });
      if (old?.is_blocked) {
        throw new HttpException(
          {
            statusCode: 403,
            message: "Qurilma bloklangan. Admin bilan bog'laning",
            error: 'Forbidden',
          },
          403,
        );
      }
      device = await this.prisma.device.upsert({
        where: { student_id: user.id },
        update: deviceData,
        create: { ...deviceData, student_id: user.id },
      });
    }

    const payload = { user_id: user.id, role: user.role, device_id: device.id };
    const { password: _pw, ...safeStudent } = user;
    return {
      user: safeStudent,
      access_token: await this.jwtService.signAsync(payload),
      device: {
        id: device.id,
        device_name: device.device_name,
        device_type: device.device_type,
      },
      message: 'Logined successfully',
    };
  }

  /**
   * Eski mobil ilova (<1.4.0) qurilmani Android build ID bilan aniqlagan
   * (u unikal emas va OS yangilanganda o'zgaradi). Yangi ilova ANDROID_ID yuboradi.
   * Agar faol qurilma eski versiyada yozilgan va model + platforma bir xil bo'lsa —
   * bu o'sha telefon deb hisoblaymiz va identifikatorni yangilashga ruxsat beramiz.
   */
  private async isLegacySameDevice(studentId: number, data: LoginDto): Promise<boolean> {
    const active = await this.prisma.device.findFirst({
      where: { student_id: studentId, is_active: true },
    });
    if (!active || !data.device) return false;
    const legacy = !active.app_version || this.versionLt(active.app_version, '1.4.0');
    return (
      legacy &&
      active.device_type === data.device.device_type &&
      active.device_name === data.device.device_name &&
      !this.versionLt(data.device.app_version ?? '0', '1.4.0')
    );
  }

  private versionLt(a: string, b: string): boolean {
    const pa = a.split('.').map((x) => parseInt(x, 10) || 0);
    const pb = b.split('.').map((x) => parseInt(x, 10) || 0);
    for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
      const x = pa[i] ?? 0;
      const y = pb[i] ?? 0;
      if (x !== y) return x < y;
    }
    return false;
  }
}
