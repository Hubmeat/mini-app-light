import { randomUUID } from 'crypto';
import { ConfigService } from '@nestjs/config';
import { Store } from '../store.interface';

/**
 * Supabase 适配器（托管 Postgres，REST 网关）。
 * 需要：npm i @supabase/supabase-js（已在 optionalDependencies）。表结构见 sql/schema.sql。
 * 注意：连阿里云 RDS PG 应用 pg.adapter，本适配器仅用于真正的 Supabase 服务。
 */
export function createSupabaseStore(config: ConfigService): Store {
  let createClient: any;
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    ({ createClient } = require('@supabase/supabase-js'));
  } catch {
    throw new Error('请先安装依赖：npm i @supabase/supabase-js');
  }
  const url = config.get<string>('supabase.url');
  const key = config.get<string>('supabase.key');
  if (!url || !key) throw new Error('缺少 SUPABASE_URL / SUPABASE_SERVICE_KEY 配置');
  const freeQuota = config.get<number>('usage.freeQuota') ?? 20;

  const sb = createClient(url, key, { auth: { persistSession: false } });
  const one = ({ data, error }: any) => {
    if (error && error.code !== 'PGRST116') throw error;
    return data || null;
  };

  const store: Store = {
    driver: 'supabase',

    users: {
      async findById(id) {
        return one(await sb.from('users').select('*').eq('id', id).maybeSingle());
      },
      async findByOpenid(openid) {
        return one(await sb.from('users').select('*').eq('openid', openid).maybeSingle());
      },
      async findByPhone(phone) {
        return one(await sb.from('users').select('*').eq('phone', phone).maybeSingle());
      },
      async create(data) {
        return one(
          await sb
            .from('users')
            .insert({
              id: randomUUID(),
              login_type: data.login_type,
              openid: data.openid ?? null,
              phone: data.phone ?? null,
              password_hash: data.password_hash ?? null,
              nickname: data.nickname ?? '光屿用户',
              used_count: 0,
              quota_limit: data.quota_limit ?? freeQuota,
            })
            .select()
            .single(),
        );
      },
      async update(id, patch) {
        return one(await sb.from('users').update(patch).eq('id', id).select().single());
      },
      async tryConsume(id, amount) {
        // 先读后写（近似）。生产建议改 Postgres rpc 单语句原子扣减。
        const u = await this.findById(id);
        if (!u) return { status: 'not_found' };
        if (u.quota_limit - u.used_count < amount) return { status: 'quota', user: u };
        const user = await this.update(id, { used_count: u.used_count + amount });
        return { status: 'ok', user: user as any };
      },
    },

    smsCodes: {
      async set(phone, code, ttlMs) {
        await sb
          .from('sms_codes')
          .upsert(
            { phone, code, expires_at: new Date(Date.now() + ttlMs).toISOString() },
            { onConflict: 'phone' },
          );
      },
      async get(phone) {
        const row = one(
          await sb.from('sms_codes').select('*').eq('phone', phone).maybeSingle(),
        );
        if (!row) return null;
        return { code: row.code, expiresAt: new Date(row.expires_at).getTime() };
      },
      async clear(phone) {
        await sb.from('sms_codes').delete().eq('phone', phone);
      },
    },

    orders: {
      async create(data) {
        return one(
          await sb
            .from('orders')
            .insert({
              id: randomUUID(),
              user_id: data.user_id,
              plan_id: data.plan_id,
              amount: data.amount,
              quota: data.quota,
              status: 'pending',
            })
            .select()
            .single(),
        );
      },
      async findById(id) {
        return one(await sb.from('orders').select('*').eq('id', id).maybeSingle());
      },
      async update(id, patch) {
        return one(await sb.from('orders').update(patch).eq('id', id).select().single());
      },
    },
  };

  return store;
}
