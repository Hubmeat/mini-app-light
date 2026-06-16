// 领域模型与跨层共享类型

export type LoginType = 'wechat' | 'phone';
export type OrderStatus = 'pending' | 'paid' | 'failed';

export interface User {
  id: string;
  login_type: LoginType;
  openid: string | null;
  phone: string | null;
  nickname: string;
  used_count: number;
  quota_limit: number;
  created_at?: string | Date;
}

export interface Order {
  id: string;
  user_id: string;
  plan_id: string;
  amount: number; // 分
  quota: number; // 该订单发放的次数
  status: OrderStatus;
  created_at?: string | Date;
}

export interface Plan {
  id: string;
  name: string;
  quota: number;
  price: number; // 分
  desc: string;
}

export interface SmsCode {
  code: string;
  expiresAt: number; // 毫秒时间戳
}

export interface CreateUserInput {
  login_type: LoginType;
  openid?: string | null;
  phone?: string | null;
  nickname?: string;
  quota_limit?: number;
}

export interface CreateOrderInput {
  user_id: string;
  plan_id: string;
  amount: number;
  quota: number;
}

/** tryConsume 的结果：原子条件扣减的三种结局 */
export type ConsumeResult =
  | { status: 'ok'; user: User }
  | { status: 'quota'; user: User }
  | { status: 'not_found' };

/** 对外暴露的用户信息（脱去敏感字段） */
export interface PublicUser {
  id: string;
  loginType: LoginType;
  nickname: string;
  usedCount: number;
  quotaLimit: number;
  remaining: number;
}

/** 用量概览 */
export interface UsageSummary {
  usedCount: number;
  quotaLimit: number;
  remaining: number;
  needPay: boolean;
}
