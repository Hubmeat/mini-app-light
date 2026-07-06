# 光屿 node-server（NestJS + TypeScript）

为「光屿」App 提供 **登录 / 用量控制 / 计费** 的后端。NestJS + TypeScript,
数据层做了**多数据库适配器抽象**(memory / postgres / mysql / supabase),可本地直接跑,
也可部署到 **阿里云函数计算 FC**。

## 技术栈

NestJS 10 · TypeScript · class-validator(DTO 校验) · @nestjs/jwt(鉴权 Guard) ·
统一响应拦截器 / 异常过滤器 · 多 DB 适配器(`pg` / `mysql2` / `@supabase/supabase-js`)

## 快速开始（零外部依赖，内存库）

```bash
cd node-server
cp .env.example .env          # 默认 DB_DRIVER=memory，微信/短信走 mock
npm install
npm run build && npm start    # http://localhost:3000
# 开发热重载：npm run start:dev
```

## 接口一览

| 方法 | 路径 | 说明 | 鉴权 |
|---|---|---|---|
| POST | `/auth/wechat` | 微信登录 `{ code }` → token | 否 |
| POST | `/auth/phone/code` | 发送验证码 `{ phone }` | 否 |
| POST | `/auth/phone/login` | 验证码登录 `{ phone, code }` → token | 否 |
| GET | `/auth/me` | 当前用户 | 是 |
| GET | `/usage/me` | 用量概览（已用/上限/剩余/是否需付费） | 是 |
| POST | `/usage/consume` | **业务接口示例**：消耗 1 次额度（超额 402） | 是 |
| GET | `/billing/plans` | 套餐列表 | 否 |
| POST | `/billing/orders` | 下单 `{ planId }` → 订单 + 支付参数 | 是 |
| POST | `/billing/orders/:id/mock-pay` | 模拟支付成功并发放配额（仅 dev） | 是 |
| POST | `/billing/notify` | 微信支付回调（占位） | 否 |

- 鉴权：登录拿到 `token` 后，请求头带 `Authorization: Bearer <token>`（`JwtAuthGuard`）。
- 响应统一为 `{ ok: true, data }` / `{ ok: false, error: { code, message } }`（拦截器 + 异常过滤器）。
- 入参由 DTO + `class-validator` 校验，失败返回 400 `VALIDATION_ERROR`。
- 注：POST 成功默认返回 201（2xx 均为成功），如需 200 可在对应方法加 `@HttpCode(200)`。

## 用量 / 计费模型

「次数包累加」：新用户赠送 `FREE_QUOTA`（默认 20）次写入 `quota_limit`，
每次业务接口 `used_count + 1`，剩余 = `quota_limit - used_count`，
用尽返回 **402 `QUOTA_EXCEEDED`**，购买套餐支付成功后 `quota_limit += plan.quota`。

**并发安全扣减**：`consume` 通过 `store.users.tryConsume` 条件扣减 —— pg/mysql 用单语句原子
`UPDATE ... WHERE quota_limit - used_count >= ?`，防高并发超扣（已用 10 并发回归验证）。

套餐在 `src/config/configuration.ts` 的 `PLANS` 配置（basic / pro / max）。

## 切换数据库（`DB_DRIVER`）

| 值 | 说明 | 配置 | 建表 |
|---|---|---|---|
| `memory` | 进程内（默认，零依赖） | — | — |
| `postgres` | 阿里云 RDS PostgreSQL 等 | `PG_HOST/PORT/USER/PASSWORD/DATABASE/SSL` | `sql/schema.sql` |
| `mysql` | 阿里云 RDS MySQL 等 | `MYSQL_HOST/PORT/USER/PASSWORD/DATABASE` | `sql/schema.mysql.sql` |
| `supabase` | Supabase 服务 | `SUPABASE_URL/SERVICE_KEY`（+`npm i @supabase/supabase-js`） | `sql/schema.sql` |

业务代码只依赖 `Store` 接口（`src/db/store.interface.ts`），换库不动 service。

## 目录结构

```
src/
├── main.ts / app.module.ts / app.controller.ts
├── config/configuration.ts            # 配置 + 套餐
├── common/                            # 异常 / 统一响应拦截器 / JwtAuthGuard / @UserId
├── models/types.ts                    # 领域类型
├── db/
│   ├── store.interface.ts             # Store 接口 + STORE token
│   ├── db.module.ts                   # 按 DB_DRIVER 选适配器（DI）
│   └── adapters/  memory · pg · mysql · supabase
├── auth/      (module · controller · service · dto)
├── usage/     (module · controller · service)
└── billing/   (module · controller · service · dto)
```

## 部署到阿里云函数计算 FC

推荐 **Web 函数（Custom Runtime）**：
- 运行环境 Node.js 18+；先 `npm run build`
- 启动命令：`node dist/main.js`
- 监听端口 `9000`，环境变量设 `PORT=9000`，其余按 `.env.example`

## 待接入（占位已留）

- 微信支付统一下单 + 回调验签（`billing.service.ts` / `/billing/notify`）
- 阿里云短信真实发送（`auth.service.ts` 的 `sendPhoneCode`）
- Supabase 并发原子扣减改 Postgres rpc（pg/mysql 已是原子）
