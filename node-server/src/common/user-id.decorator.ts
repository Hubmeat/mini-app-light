import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/** 取出 JwtAuthGuard 挂载的当前用户 id。 */
export const UserId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string =>
    ctx.switchToHttp().getRequest().userId,
);
