import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  check(): string {
    return this.appService.check();
  }

  /** Docker healthcheck va monitoring uchun. */
  @Get('health')
  health() {
    return this.appService.health();
  }

  @Get('version')
  getAppVersion() {
    return this.appService.getAppVersion();
  }
}
