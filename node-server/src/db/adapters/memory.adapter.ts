import { randomUUID } from 'crypto';
import { Order, SmsCode, User } from '../../models/types';
import { Store } from '../store.interface';

/** 进程内内存适配器：零依赖、重启清空，仅用于本地/演示。单进程串行，扣减天然安全。 */
export function createMemoryStore(freeQuota = 20): Store {
  const users = new Map<string, User>();
  const smsCodes = new Map<string, SmsCode>();
  const orders = new Map<string, Order>();

  const find = <T>(map: Map<string, T>, pred: (v: T) => boolean): T | null => {
    for (const v of map.values()) if (pred(v)) return v;
    return null;
  };

  return {
    driver: 'memory',

    users: {
      async findById(id) {
        return users.get(id) ?? null;
      },
      async findByOpenid(openid) {
        return find(users, (u) => u.openid === openid);
      },
      async findByPhone(phone) {
        return find(users, (u) => u.phone === phone);
      },
      async create(data) {
        const user: User = {
          id: randomUUID(),
          login_type: data.login_type,
          openid: data.openid ?? null,
          phone: data.phone ?? null,
          password_hash: data.password_hash ?? null,
          nickname: data.nickname ?? '光屿用户',
          used_count: 0,
          quota_limit: data.quota_limit ?? freeQuota,
          created_at: new Date().toISOString(),
        };
        users.set(user.id, user);
        return user;
      },
      async update(id, patch) {
        const u = users.get(id);
        if (!u) return null;
        Object.assign(u, patch);
        return u;
      },
      async tryConsume(id, amount) {
        const u = users.get(id);
        if (!u) return { status: 'not_found' };
        if (u.quota_limit - u.used_count < amount) {
          return { status: 'quota', user: u };
        }
        u.used_count += amount;
        return { status: 'ok', user: u };
      },
    },

    smsCodes: {
      async set(phone, code, ttlMs) {
        smsCodes.set(phone, { code, expiresAt: Date.now() + ttlMs });
      },
      async get(phone) {
        return smsCodes.get(phone) ?? null;
      },
      async clear(phone) {
        smsCodes.delete(phone);
      },
    },

    orders: {
      async create(data) {
        const order: Order = {
          id: randomUUID(),
          user_id: data.user_id,
          plan_id: data.plan_id,
          amount: data.amount,
          quota: data.quota,
          status: 'pending',
          created_at: new Date().toISOString(),
        };
        orders.set(order.id, order);
        return order;
      },
      async findById(id) {
        return orders.get(id) ?? null;
      },
      async update(id, patch) {
        const o = orders.get(id);
        if (!o) return null;
        Object.assign(o, patch);
        return o;
      },
    },
  };
}
