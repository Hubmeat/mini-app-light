import { randomUUID } from 'crypto';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';
import { Order, User } from '../../models/types';
import { Store } from '../store.interface';

/**
 * 阿里云 RDS PostgreSQL（或任意 PostgreSQL）适配器，node-postgres 连接池。
 * 直连 RDS PG 用本适配器；Supabase 走 supabase.adapter（REST 网关），两者不同。
 */
export function createPgStore(config: ConfigService): Store {
  const host = config.get<string>('pg.host');
  const user = config.get<string>('pg.user');
  const database = config.get<string>('pg.database');
  if (!host || !user || !database) {
    throw new Error('缺少 PG_HOST / PG_USER / PG_DATABASE 配置');
  }
  const freeQuota = config.get<number>('usage.freeQuota') ?? 20;

  const pool = new Pool({
    host,
    port: config.get<number>('pg.port'),
    user,
    password: config.get<string>('pg.password'),
    database,
    max: 10,
    ssl: config.get<boolean>('pg.ssl') ? { rejectUnauthorized: false } : false,
  });

  const q = async <T = any>(text: string, params: any[] = []): Promise<T[]> =>
    (await pool.query(text, params)).rows as T[];
  const first = <T>(rows: T[]): T | null => (rows.length ? rows[0] : null);
  const findUserById = (id: string) =>
    q<User>('SELECT * FROM users WHERE id = $1', [id]).then(first);

  return {
    driver: 'postgres',

    users: {
      findById: findUserById,
      async findByOpenid(openid) {
        return first(await q<User>('SELECT * FROM users WHERE openid = $1', [openid]));
      },
      async findByPhone(phone) {
        return first(await q<User>('SELECT * FROM users WHERE phone = $1', [phone]));
      },
      async create(data) {
        return first(
          await q<User>(
            `INSERT INTO users (id, login_type, openid, phone, nickname, used_count, quota_limit)
             VALUES ($1, $2, $3, $4, $5, 0, $6) RETURNING *`,
            [
              randomUUID(),
              data.login_type,
              data.openid ?? null,
              data.phone ?? null,
              data.nickname ?? '光屿用户',
              data.quota_limit ?? freeQuota,
            ],
          ),
        ) as User;
      },
      async update(id, patch) {
        const keys = Object.keys(patch);
        if (!keys.length) return findUserById(id);
        const set = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
        return first(
          await q<User>(
            `UPDATE users SET ${set} WHERE id = $${keys.length + 1} RETURNING *`,
            [...keys.map((k) => (patch as any)[k]), id],
          ),
        );
      },
      async tryConsume(id, amount) {
        const rows = await q<User>(
          `UPDATE users SET used_count = used_count + $2
             WHERE id = $1 AND quota_limit - used_count >= $2 RETURNING *`,
          [id, amount],
        );
        if (rows.length) return { status: 'ok', user: rows[0] };
        const user = await findUserById(id);
        return user ? { status: 'quota', user } : { status: 'not_found' };
      },
    },

    smsCodes: {
      async set(phone, code, ttlMs) {
        await q(
          `INSERT INTO sms_codes (phone, code, expires_at) VALUES ($1, $2, $3)
           ON CONFLICT (phone) DO UPDATE SET code = EXCLUDED.code, expires_at = EXCLUDED.expires_at`,
          [phone, code, new Date(Date.now() + ttlMs).toISOString()],
        );
      },
      async get(phone) {
        const row = first(
          await q<any>('SELECT * FROM sms_codes WHERE phone = $1', [phone]),
        );
        if (!row) return null;
        return { code: row.code, expiresAt: new Date(row.expires_at).getTime() };
      },
      async clear(phone) {
        await q('DELETE FROM sms_codes WHERE phone = $1', [phone]);
      },
    },

    orders: {
      async create(data) {
        return first(
          await q<Order>(
            `INSERT INTO orders (id, user_id, plan_id, amount, quota, status)
             VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *`,
            [randomUUID(), data.user_id, data.plan_id, data.amount, data.quota],
          ),
        ) as Order;
      },
      async findById(id) {
        return first(await q<Order>('SELECT * FROM orders WHERE id = $1', [id]));
      },
      async update(id, patch) {
        const keys = Object.keys(patch);
        if (!keys.length) return first(await q<Order>('SELECT * FROM orders WHERE id = $1', [id]));
        const set = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
        return first(
          await q<Order>(
            `UPDATE orders SET ${set} WHERE id = $${keys.length + 1} RETURNING *`,
            [...keys.map((k) => (patch as any)[k]), id],
          ),
        );
      },
    },
  };
}
