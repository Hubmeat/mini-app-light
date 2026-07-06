import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomBytes, scrypt, timingSafeEqual } from 'crypto';
import { promisify } from 'util';
import { BizException } from '../common/biz-exception';
import { STORE, Store } from '../db/store.interface';
import { PublicUser, User } from '../models/types';

const scryptAsync = promisify(scrypt);

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

  /**
   * 移动端 OAuth：用 code 换 access_token + openid。
   * 未配置 AppID/Secret 时走 mock（方便本地联调）。
   */
  private async wechatMobileOAuth(code: string): Promise<{ openid: string; nickname?: string }> {
    const appId = this.config.get<string>('wechat.appId');
    const secret = this.config.get<string>('wechat.secret');
    if (!appId || !secret) {
      this.logger.warn('[wechat:mock] 未配置 AppID/Secret，使用 mock openid');
      return { openid: `mock_${code}` };
    }

    // Step 1: code → access_token + openid
    const tokenUrl =
      `https://api.weixin.qq.com/sns/oauth2/access_token?appid=${appId}` +
      `&secret=${secret}&code=${code}&grant_type=authorization_code`;
    const tokenResp = await fetch(tokenUrl);
    const tokenJson: any = await tokenResp.json();
    if (tokenJson.errcode) {
      throw new BizException(401, 'WECHAT_AUTH_FAILED', `微信授权失败：${tokenJson.errmsg}`);
    }
    const { access_token, openid } = tokenJson;

    // Step 2: access_token + openid → 用户信息（昵称等）
    try {
      const infoUrl =
        `https://api.weixin.qq.com/sns/userinfo?access_token=${access_token}` +
        `&openid=${openid}&lang=zh_CN`;
      const infoResp = await fetch(infoUrl);
      const infoJson: any = await infoResp.json();
      return { openid, nickname: infoJson.nickname };
    } catch {
      return { openid };
    }
  }

  async loginWithWechat(code: string) {
    if (!code) throw new BizException(400, 'BAD_REQUEST', '缺少 code');
    const { openid, nickname } = await this.wechatMobileOAuth(code);
    let user = await this.store.users.findByOpenid(openid);
    if (!user) {
      user = await this.store.users.create({
        login_type: 'wechat',
        openid,
        nickname: nickname || '光屿用户',
        quota_limit: this.freeQuota(),
      });
    } else if (nickname && user.nickname === '光屿用户') {
      await this.store.users.update(user.id, { nickname });
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

  private async hashPassword(password: string): Promise<string> {
    const salt = randomBytes(16).toString('hex');
    const hash = (await scryptAsync(password, salt, 32)) as Buffer;
    return `${salt}:${hash.toString('hex')}`;
  }

  private async verifyPassword(password: string, stored: string): Promise<boolean> {
    const [salt, hashHex] = stored.split(':');
    const hash = (await scryptAsync(password, salt, 32)) as Buffer;
    const storedHash = Buffer.from(hashHex, 'hex');
    return timingSafeEqual(hash, storedHash);
  }

  async registerWithPhonePassword(phone: string, password: string) {
    const existing = await this.store.users.findByPhone(phone);
    if (existing) {
      throw new BizException(409, 'PHONE_EXISTS', '该手机号已注册');
    }
    const password_hash = await this.hashPassword(password);
    const user = await this.store.users.create({
      login_type: 'phone',
      phone,
      password_hash,
      quota_limit: this.freeQuota(),
    });
    return this.issue(user);
  }

  async loginWithPhonePassword(phone: string, password: string) {
    const user = await this.store.users.findByPhone(phone);
    if (!user || !user.password_hash) {
      throw new BizException(401, 'INVALID_CREDENTIALS', '手机号或密码错误');
    }
    const ok = await this.verifyPassword(password, user.password_hash);
    if (!ok) {
      throw new BizException(401, 'INVALID_CREDENTIALS', '手机号或密码错误');
    }
    return this.issue(user);
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
