import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { Request } from 'express';
import { Role } from '@prisma/client';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    @Inject() private prismaService: PrismaClientService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      const request = context.switchToHttp().getRequest();
      const token = this.extractTokenFromHeader(request);

      if (!token) {
        throw new UnauthorizedException();
      }

      const payload: {
        role: Role;
        user_id: number;
        device_id?: number;
      } = await this.jwtService.verifyAsync(token);

      // Check device if device_id exists in payload
      if (payload.device_id) {
        const device = await this.prismaService.device.findUnique({
          where: { id: payload.device_id },
          select: { id: true, is_active: true, is_blocked: true },
        });

        if (!device) {
          throw new UnauthorizedException({
            statusCode: 401,
            message: 'Qurilma topilmadi',
            error: 'Unauthorized',
          });
        }

        if (device.is_blocked) {
          throw new UnauthorizedException({
            statusCode: 401,
            message: 'Qurilma bloklangan',
            error: 'Unauthorized',
          });
        }

        if (!device.is_active) {
          throw new UnauthorizedException({
            statusCode: 401,
            message: 'Qurilma faol emas',
            error: 'Unauthorized',
          });
        }

        // Update device activity (fire and forget - no await)
        const ipAddress =
          request.ip ||
          request.headers['x-forwarded-for'] ||
          request.connection?.remoteAddress;
        this.prismaService.device
          .update({
            where: { id: device.id },
            data: {
              last_active: new Date(),
              last_api_endpoint: request.url,
              last_api_method: request.method,
              ip_address: ipAddress,
            },
          })
          .catch(() => {
            // Silent error - don't block request
          });
      }

      const where = { id: payload.user_id };
      let user: any;
      if (payload.role == Role.STUDENT) {
        user = await this.prismaService.student.findUnique({
          where,
        });
      } else if (payload.role == Role.TEACHER) {
        user = await this.prismaService.teacher.findUnique({
          where,
        });
      } else if (payload.role == Role.ADMIN) {
        user = await this.prismaService.admin.findUnique({
          where,
        });
      }

      if (!user) {
        throw new UnauthorizedException();
      }

      request['user'] = { ...user, role: payload.role };

      return true;
    } catch (error) {
      // If it's already an UnauthorizedException with custom message, re-throw it
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      // Otherwise throw generic unauthorized error
      throw new UnauthorizedException();
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
