import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { UserId } from '../common/user-id.decorator';
import { UsageService } from './usage.service';

@Controller('usage')
@UseGuards(JwtAuthGuard)
export class UsageController {
  constructor(private readonly usage: UsageService) {}

  // 当前用户用量
  @Get('me')
  me(@UserId() userId: string) {
    return this.usage.getUsage(userId);
  }

  // 受配额保护的「业务接口」示例：调用即消耗一次额度，用尽返回 402。
  @Post('consume')
  async consume(@UserId() userId: string) {
    const r = await this.usage.consume(userId, 1);
    return { consumed: 1, ...r };
  }
}
