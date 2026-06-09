import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BizException } from '../common/biz-exception';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { UserId } from '../common/user-id.decorator';
import { BillingService } from './billing.service';
import { CreateOrderDto } from './dto';

@Controller('billing')
export class BillingController {
  constructor(
    private readonly billing: BillingService,
    private readonly config: ConfigService,
  ) {}

  // 套餐列表（公开）
  @Get('plans')
  plans() {
    return { plans: this.billing.listPlans() };
  }

  // 下单
  @Post('orders')
  @UseGuards(JwtAuthGuard)
  createOrder(@UserId() userId: string, @Body() dto: CreateOrderDto) {
    return this.billing.createOrder(userId, dto.planId);
  }

  // 模拟支付成功（仅开发环境）：打通「下单→支付→发放配额」整条链路
  @Post('orders/:id/mock-pay')
  @UseGuards(JwtAuthGuard)
  mockPay(@Param('id') id: string) {
    if (this.config.get<string>('env') === 'production') {
      throw new BizException(403, 'FORBIDDEN', '生产环境禁用模拟支付');
    }
    return this.billing.markPaidAndGrant(id);
  }

  // 微信支付回调（占位）：生产需验签后调用 markPaidAndGrant
  @Post('notify')
  notify() {
    // TODO 验签 + 解析 out_trade_no，再 billing.markPaidAndGrant(orderId)
    return { code: 'SUCCESS', message: 'OK' };
  }
}
