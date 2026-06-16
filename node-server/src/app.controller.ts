import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  root() {
    return { service: 'guangyu-server', status: 'ok' };
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }
}
