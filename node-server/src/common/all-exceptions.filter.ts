import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';

/** 统一错误响应：{ ok:false, error:{ code, message } }。 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exception');

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    let status: number = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_ERROR';
    let message = '服务器内部错误';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      if (typeof body === 'string') {
        code = 'ERROR';
        message = body;
      } else if (body && typeof body === 'object') {
        const b = body as Record<string, unknown>;
        // ValidationPipe 抛的 message 是数组
        if (Array.isArray(b.message)) {
          code = 'VALIDATION_ERROR';
          message = (b.message as string[]).join('; ');
        } else {
          code = (b.code as string) || 'ERROR';
          message = (b.message as string) || message;
        }
      }
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    if (status >= 500) this.logger.error(exception);
    res.status(status).json({ ok: false, error: { code, message } });
  }
}
