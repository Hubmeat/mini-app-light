import { randomUUID } from 'crypto';
import { ConfigService } from '@nestjs/config';
import mysql from 'mysql2/promise';
import { Order, User } from '../../models/types';
import { Store } from '../store.interface';

/** 阿里云 RDS MySQL（或任意 MySQL）适配器，mysql2 连接池。表结构见 sql/schema.mysql.sql。 */
export function createMysqlStore(config: ConfigService): Store {
  const host = config.get<string>('mysql.host');
  const user = config.get<string>('mysql.user');
  const database = config.get<string>('mysql.database');
  if (!host || !user || !database) {
    throw new Error('缺少 MYSQL_HOST / MYSQL_USER / MYSQL_DATABASE 配置');
  }
  const freeQuota = config.get<number>('usage.freeQuota') ?? 20;

  const pool = mysql.createPool({
    host,
    port: config.get<number>('mysql.port'),
    user,
    password: config.get<string>('mysql.password'),
    database,
    waitForConnections: true,
    connectionLimit: 10,
    charset: 'utf8mb4',
    timezone: 'Z',
  });

  const rows = async <T = any>(sql: string, params: any[] = []): Promise<T[]> => {
    const [r] = await pool.query(sql, params);
    return r as T[];
  };
  const exec = async (sql: string, params: any[] = []): Promise<any> => {
    const [r] = await pool.execute(sql, params);
    return r;
  };
  const first = <T>(arr: T[]): T | null => (arr.length ? arr[0] : null);
  const findUserById = (id: string) =>
    rows<User>('SELECT * FROM users WHERE id = ? LIMIT 1', [id]).then(first);

  return {
    driver: 'mysql',

    users: {
      findById: findUserById,
      async findByOpenid(openid) {
        return first(await rows<User>('SELECT * FROM users WHERE openid = ? LIMIT 1', [openid]));
      },
      async findByPhone(phone) {
        return first(await rows<User>('SELECT * FROM users WHERE phone = ? LIMIT 1', [phone]));
      },
      async create(data) {
        const id = randomUUID();
        await exec(
          `INSERT INTO users (id, login_type, openid, phone, password_hash, nickname, used_count, quota_limit)
           VALUES (?, ?, ?, ?, ?, ?, 0, ?)`,
          [
            id,
            data.login_type,
            data.openid ?? null,
            data.phone ?? null,
            data.password_hash ?? null,
            data.nickname ?? '光屿用户',
            data.quota_limit ?? freeQuota,
          ],
        );
        return (await findUserById(id)) as User;
      },
      async update(id, patch) {
        const keys = Object.keys(patch);
        if (!keys.length) return findUserById(id);
        const set = keys.map((k) => `${k} = ?`).join(', ');
        await exec(`UPDATE users SET ${set} WHERE id = ?`, [
          ...keys.map((k) => (patch as any)[k]),
          id,
        ]);
        return findUserById(id);
      },
      async tryConsume(id, amount) {
        const res = await exec(
          `UPDATE users SET used_count = used_count + ?
             WHERE id = ? AND quota_limit - used_count >= ?`,
          [amount, id, amount],
        );
        if (res.affectedRows === 1) {
          return { status: 'ok', user: (await findUserById(id)) as User };
        }
        const user = await findUserById(id);
        return user ? { status: 'quota', user } : { status: 'not_found' };
      },
    },

    smsCodes: {
      async set(phone, code, ttlMs) {
        await exec(
          `INSERT INTO sms_codes (phone, code, expires_at) VALUES (?, ?, ?)
           ON DUPLICATE KEY UPDATE code = VALUES(code), expires_at = VALUES(expires_at)`,
          [phone, code, new Date(Date.now() + ttlMs)],
        );
      },
      async get(phone) {
        const row = first(
          await rows<any>('SELECT * FROM sms_codes WHERE phone = ? LIMIT 1', [phone]),
        );
        if (!row) return null;
        return { code: row.code, expiresAt: new Date(row.expires_at).getTime() };
      },
      async clear(phone) {
        await exec('DELETE FROM sms_codes WHERE phone = ?', [phone]);
      },
    },

    orders: {
      async create(data) {
        const id = randomUUID();
        await exec(
          `INSERT INTO orders (id, user_id, plan_id, amount, quota, status)
           VALUES (?, ?, ?, ?, ?, 'pending')`,
          [id, data.user_id, data.plan_id, data.amount, data.quota],
        );
        return first(await rows<Order>('SELECT * FROM orders WHERE id = ? LIMIT 1', [id])) as Order;
      },
      async findById(id) {
        return first(await rows<Order>('SELECT * FROM orders WHERE id = ? LIMIT 1', [id]));
      },
      async update(id, patch) {
        const keys = Object.keys(patch);
        if (keys.length) {
          const set = keys.map((k) => `${k} = ?`).join(', ');
          await exec(`UPDATE orders SET ${set} WHERE id = ?`, [
            ...keys.map((k) => (patch as any)[k]),
            id,
          ]);
        }
        return first(await rows<Order>('SELECT * FROM orders WHERE id = ? LIMIT 1', [id]));
      },
    },
  };
}
