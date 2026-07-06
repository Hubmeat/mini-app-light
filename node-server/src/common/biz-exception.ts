import { HttpException } from '@nestjs/common';

/** 业务异常：携带 HTTP 状态码 + 业务 code，由 AllExceptionsFilter 统一成 {ok:false,error}。 */
export class BizException extends HttpException {
  constructor(
    status: number,
    public readonly code: string,
    message: string,
  ) {
    super({ code, message }, status);
  }
}
