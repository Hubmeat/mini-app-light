import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { BizException } from '../common/biz-exception';
import { STORE, Store } from '../db/store.interface';
import { PublicUser, User } from '../models/types';

const SMS_TTL_MS = 5 * 60 * 1000; // 验证码 5 分钟有效

@Injectable()
export class AuthService {
  private readonly logger = new Logger('Auth');

  constructor(
    @Inject(STORE) private readonly store: Store,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  publicUser(u: User): PublicUser {
    return {
      id: u.id,
      loginType: u.login_type,
      nickname: u.nickname,
      usedCount: u.used_count,
      quotaLimit: u.quota_limit,
      remaining: Math.max(0, u.quota_limit - u.used_count),
    };
  }

  private freeQuota(): number {
    return this.config.get<number>('usage.freeQuota') ?? 20;
  }

  private sign(u: User): string {
    return this.jwt.sign({ sub: u.id, loginType: u.login_type });
  }

  private issue(user: User) {
    return { token: this.sign(user), user: this.publicUser(user) };
  }

  /** 用小程序 code 换 openid；未配置 AppID/Secret 时走 mock。 */
  private async wechatCode2Session(code: string): Promise<{ openid: string }> {
    const appId = this.config.get<string>('wechat.appId');
    const secret = this.config.get<string>('wechat.secret');
    if (!appId || !secret) return { openid: `mock_${code}` };
    const url =
      `https://api.weixin.qq.com/sns/jscode2session?appid=${appId}` +
      `&secret=${secret}&js_code=${code}&grant_type=authorization_code`;
    const resp = await fetch(url);
    const json: any = await resp.json();
    if (json.errcode) {
      throw new BizException(401, 'WECHAT_AUTH_FAILED', `微信登录失败：${json.errmsg}`);
    }
    return { openid: json.openid };
  }

  async loginWithWechat(code: string) {
    if (!code) throw new BizException(400, 'BAD_REQUEST', '缺少 code');
    const { openid } = await this.wechatCode2Session(code);
    let user = await this.store.users.findByOpenid(openid);
    if (!user) {
      user = await this.store.users.create({
        login_type: 'wechat',
        openid,
        quota_limit: this.freeQuota(),
      });
    }
    return this.issue(user);
  }

  /** 发送手机验证码；未配置阿里云短信时走 mock（在返回里带 devCode）。 */
  async sendPhoneCode(phone: string) {
    const code = String(Math.floor(100000 + Math.random() * 900000));
    await this.store.smsCodes.set(phone, code, SMS_TTL_MS);
    const mock = !this.config.get<string>('sms.accessKeyId');
    if (mock) {
      this.logger.log(`[sms:mock] 向 ${phone} 发送验证码：${code}`);
    } else {
      // TODO 接入阿里云短信 Dysmsapi SendSms
      throw new BizException(500, 'SMS_NOT_IMPLEMENTED', '阿里云短信尚未接入');
    }
    return { sent: true, devCode: mock ? code : undefined };
  }

  async loginWithPhone(phone: string, code: string) {
    const rec = await this.store.smsCodes.get(phone);
    if (!rec || rec.expiresAt < Date.now()) {
      throw new BizException(401, 'CODE_EXPIRED', '验证码不存在或已过期');
    }
    if (rec.code !== String(code)) {
      throw new BizException(401, 'CODE_INVALID', '验证码错误');
    }
    await this.store.smsCodes.clear(phone);

    let user = await this.store.users.findByPhone(phone);
    if (!user) {
      user = await this.store.users.create({
        login_type: 'phone',
        phone,
        quota_limit: this.freeQuota(),
      });
    }
    return this.issue(user);
  }
}
