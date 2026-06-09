import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/** 把 controller 返回值统一包成 { ok: true, data }。 */
@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, { ok: true; data: T }>
{
  intercept(
    _ctx: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<{ ok: true; data: T }> {
    return next.handle().pipe(map((data) => ({ ok: true, data: data ?? ({} as T) })));
  }
}
