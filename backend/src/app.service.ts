import { Injectable } from '@nestjs/common';
import { PrismaClientService } from './_prisma_client/prisma_client.service';
import { RedisService } from './_redis/redis.service';

@Injectable()
export class AppService {
  constructor(
    private readonly prisma: PrismaClientService,
    private readonly redis: RedisService,
  ) {}

  check(): string {
    return 'Mahad test server is working !!!\n';
  }

  async health() {
    let db = false;
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      db = true;
    } catch {
      db = false;
    }
    return {
      status: db ? 'ok' : 'degraded',
      db,
      redis: await this.redis.ping(),
      uptime: Math.round(process.uptime()),
      version: process.env.APP_VERSION ?? '1.0.0',
    };
  }

  getAppVersion() {
    return {
      version: process.env.APP_VERSION ?? '1.0.0',
    };
  }
}
