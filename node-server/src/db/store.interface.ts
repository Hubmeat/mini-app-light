import {
  ConsumeResult,
  CreateOrderInput,
  CreateUserInput,
  Order,
  SmsCode,
  User,
} from '../models/types';

export interface UserStore {
  findById(id: string): Promise<User | null>;
  findByOpenid(openid: string): Promise<User | null>;
  findByPhone(phone: string): Promise<User | null>;
  create(data: CreateUserInput): Promise<User>;
  update(id: string, patch: Partial<User>): Promise<User | null>;
  /** 原子条件扣减：剩余足够才 +amount。 */
  tryConsume(id: string, amount: number): Promise<ConsumeResult>;
}

export interface SmsCodeStore {
  set(phone: string, code: string, ttlMs: number): Promise<void>;
  get(phone: string): Promise<SmsCode | null>;
  clear(phone: string): Promise<void>;
}

export interface OrderStore {
  create(data: CreateOrderInput): Promise<Order>;
  findById(id: string): Promise<Order | null>;
  update(id: string, patch: Partial<Order>): Promise<Order | null>;
}

/** 统一存储接口。所有数据库适配器实现它，业务层只依赖此接口。 */
export interface Store {
  readonly driver: string;
  users: UserStore;
  smsCodes: SmsCodeStore;
  orders: OrderStore;
}

/** 依赖注入 token。 */
export const STORE = Symbol('STORE');
