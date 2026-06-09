-- 光屿 server 数据表（PostgreSQL / Supabase 通用）
-- 在 Supabase SQL Editor 直接执行即可。

-- 用户表：一个用户对应一种登录方式（微信 openid 或 手机号）
create table if not exists users (
  id          uuid primary key,
  login_type  text not null check (login_type in ('wechat', 'phone')),
  openid      text unique,                 -- 微信登录
  phone       text unique,                 -- 手机号登录
  nickname    text default '光屿用户',
  used_count  integer not null default 0,  -- 已用次数
  quota_limit integer not null default 20, -- 可用次数上限（免费额度 + 已购）
  created_at  timestamptz not null default now()
);

-- 短信验证码表（按手机号覆盖；也可换用 Redis）
create table if not exists sms_codes (
  phone      text primary key,
  code       text not null,
  expires_at timestamptz not null
);

-- 订单表
create table if not exists orders (
  id         uuid primary key,
  user_id    uuid not null references users(id) on delete cascade,
  plan_id    text not null,
  amount     integer not null,             -- 金额（分）
  quota      integer not null,             -- 该订单发放的次数
  status     text not null default 'pending'
             check (status in ('pending', 'paid', 'failed')),
  created_at timestamptz not null default now()
);

create index if not exists idx_orders_user on orders(user_id);

-- 并发安全的扣减建议（服务端用 service key 执行，绕过 RLS）：
--   update users set used_count = used_count + 1
--   where id = $1 and used_count < quota_limit
--   returning *;
-- 若返回 0 行，则表示额度已用尽，应提示购买。
