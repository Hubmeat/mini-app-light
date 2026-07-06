import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { BizException } from './biz-exception';

/** 校验 Authorization: Bearer <token>，把 userId / loginType 挂到 request。 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest<Request & { userId?: string; loginType?: string }>();
    const header = (req.headers['authorization'] as string) || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw new BizException(401, 'NO_TOKEN', '未登录');
    try {
      const payload = this.jwt.verify<{ sub: string; loginType: string }>(token);
      req.userId = payload.sub;
      req.loginType = payload.loginType;
      return true;
    } catch {
      throw new BizException(401, 'TOKEN_INVALID', '登录已失效，请重新登录');
    }
  }
}
