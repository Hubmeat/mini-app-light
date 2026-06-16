import { Inject, Injectable } from '@nestjs/common';
import { BizException } from '../common/biz-exception';
import { STORE, Store } from '../db/store.interface';
import { UsageSummary, User } from '../models/types';

@Injectable()
export class UsageService {
  constructor(@Inject(STORE) private readonly store: Store) {}

  private summarize(u: User): UsageSummary {
    const remaining = Math.max(0, u.quota_limit - u.used_count);
    return {
      usedCount: u.used_count,
      quotaLimit: u.quota_limit,
      remaining,
      needPay: remaining <= 0,
    };
  }

  async getUsage(userId: string): Promise<UsageSummary> {
    const u = await this.store.users.findById(userId);
    if (!u) throw new BizException(404, 'USER_NOT_FOUND', '用户不存在');
    return this.summarize(u);
  }

  /** 消耗 amount 次额度（条件原子扣减）。用尽抛 402。 */
  async consume(userId: string, amount = 1): Promise<UsageSummary> {
    const r = await this.store.users.tryConsume(userId, amount);
    if (r.status === 'not_found') {
      throw new BizException(404, 'USER_NOT_FOUND', '用户不存在');
    }
    if (r.status === 'quota') {
      throw new BizException(
        402,
        'QUOTA_EXCEEDED',
        '免费/剩余次数已用完，请购买次数包后继续',
      );
    }
    return this.summarize(r.user);
  }

  /** 购买成功后增加配额。 */
  async grantQuota(userId: string, quota: number): Promise<UsageSummary> {
    const u = await this.store.users.findById(userId);
    if (!u) throw new BizException(404, 'USER_NOT_FOUND', '用户不存在');
    const updated = await this.store.users.update(userId, {
      quota_limit: u.quota_limit + quota,
    });
    return this.summarize(updated as User);
  }
}
