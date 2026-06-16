import { Plan } from '../models/types';

const num = (v: string | undefined, d: number): number =>
  v === undefined || v === '' ? d : Number(v);

/** 计费套餐（次数包）。生产可改为入库可配置。 */
export const PLANS: Plan[] = [
  { id: 'basic', name: '基础包', quota: 100, price: 990, desc: '100 次 · ¥9.9' },
  { id: 'pro', name: '畅享包', quota: 500, price: 2990, desc: '500 次 · ¥29.9' },
  { id: 'max', name: '尊享包', quota: 2000, price: 9900, desc: '2000 次 · ¥99' },
];

/** 全局配置（由 @nestjs/config 加载，ConfigService.get('jwt.secret') 形式访问） */
export default () => ({
  env: process.env.NODE_ENV || 'development',
  port: num(process.env.PORT, 3000),

  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },

  db: {
    driver: process.env.DB_DRIVER || 'memory', // memory | postgres | mysql | supabase
  },

  pg: {
    host: process.env.PG_HOST || '',
    port: num(process.env.PG_PORT, 5432),
    user: process.env.PG_USER || '',
    password: process.env.PG_PASSWORD || '',
    database: process.env.PG_DATABASE || '',
    ssl: (process.env.PG_SSL || 'false') === 'true',
  },

  mysql: {
    host: process.env.MYSQL_HOST || '',
    port: num(process.env.MYSQL_PORT, 3306),
    user: process.env.MYSQL_USER || '',
    password: process.env.MYSQL_PASSWORD || '',
    database: process.env.MYSQL_DATABASE || '',
  },

  supabase: {
    url: process.env.SUPABASE_URL || '',
    key: process.env.SUPABASE_SERVICE_KEY || '',
  },

  usage: {
    freeQuota: num(process.env.FREE_QUOTA, 20),
  },

  wechat: {
    appId: process.env.WECHAT_APPID || '',
    secret: process.env.WECHAT_SECRET || '',
  },

  sms: {
    accessKeyId: process.env.ALIYUN_SMS_ACCESS_KEY_ID || '',
    accessKeySecret: process.env.ALIYUN_SMS_ACCESS_KEY_SECRET || '',
    signName: process.env.ALIYUN_SMS_SIGN_NAME || '',
    templateCode: process.env.ALIYUN_SMS_TEMPLATE_CODE || '',
  },

  plans: PLANS,
});
