import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BizException } from '../common/biz-exception';
import { STORE, Store } from '../db/store.interface';
import { Order, Plan } from '../models/types';
import { UsageService } from '../usage/usage.service';

@Injectable()
export class BillingService {
  constructor(
    @Inject(STORE) private readonly store: Store,
    private readonly config: ConfigService,
    private readonly usage: UsageService,
  ) {}

  listPlans(): Plan[] {
    return this.config.get<Plan[]>('plans') ?? [];
  }

  private findPlan(id: string): Plan | null {
    return this.listPlans().find((p) => p.id === id) ?? null;
  }

  /**
   * 下单：创建 pending 订单。
   * 真实场景这里调用微信支付「统一下单」返回 payParams；当前为占位 null。
   */
  async createOrder(userId: string, planId: string) {
    const plan = this.findPlan(planId);
    if (!plan) throw new BizException(400, 'PLAN_NOT_FOUND', '套餐不存在');
    const order = await this.store.orders.create({
      user_id: userId,
      plan_id: plan.id,
      amount: plan.price,
      quota: plan.quota,
    });
    return { order, payParams: null };
  }

  /**
   * 标记订单已支付并发放配额。
   * dev：由 /billing/orders/:id/mock-pay 调用；生产：由微信支付回调验签后调用。
   */
  async markPaidAndGrant(orderId: string) {
    const order = await this.store.orders.findById(orderId);
    if (!order) throw new BizException(404, 'ORDER_NOT_FOUND', '订单不存在');
    if (order.status === 'paid') {
      return { order, usage: null, alreadyPaid: true };
    }
    const paid: Order | null = await this.store.orders.update(orderId, {
      status: 'paid',
    });
    const usage = await this.usage.grantQuota(order.user_id, order.quota);
    return { order: paid, usage, alreadyPaid: false };
  }
}
