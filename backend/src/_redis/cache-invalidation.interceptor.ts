import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { ContentPrefixes } from './redis.module';
import { RedisService } from './redis.service';

/**
 * Har qanday muvaffaqiyatli o'zgartiruvchi so'rovdan (POST/PUT/PATCH/DELETE) keyin
 * tegishli kesh guruhini tozalaydi. Shu sabab servislar ichida kesh tozalashni
 * unutib qo'yish xavfi yo'q.
 */
@Injectable()
export class CacheInvalidationInterceptor implements NestInterceptor {
  constructor(private readonly redis: RedisService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest();
    const method: string = req.method;
    if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') {
      return next.handle();
    }
    const path: string = (req.originalUrl ?? req.url ?? '').split('?')[0].replace(/^\/api\/v1/, '');
    const prefixes = new Set<string>();

    if (/^\/(subject|book|section|test|test-item)(\/|$)/.test(path)) {
      ContentPrefixes.forEach((p) => prefixes.add(p));
    }
    if (/^\/special-test(\/|$)/.test(path)) {
      ContentPrefixes.forEach((p) => prefixes.add(p));
      prefixes.add('rate:');
    }
    if (/^\/(result|student|group)(\/|$)/.test(path)) {
      prefixes.add('rate:');
      prefixes.add('group:');
    }
    if (prefixes.size === 0 || path.startsWith('/auth') || path === '/test/random') {
      return next.handle();
    }
    return next.handle().pipe(
      tap(() => {
        void this.redis.del(...prefixes);
      }),
    );
  }
}
