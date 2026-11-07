import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

/**
 * Redis kesh va hisoblagichlar.
 * REDIS_URL berilmasa yoki Redis ishlamasa — hamma metodlar "bypass" qiladi,
 * ya'ni ilova Redis'siz ham to'liq ishlaydi (faqat keshsiz).
 */
@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger('Redis');
  private readonly client: Redis | null;
  private readonly prefix = process.env.REDIS_PREFIX ?? 'mahad:';
  private warned = false;

  constructor() {
    const url = process.env.REDIS_URL;
    if (!url) {
      this.logger.warn('REDIS_URL berilmagan — kesh o‘chirilgan');
      this.client = null;
      return;
    }
    this.client = new Redis(url, {
      lazyConnect: false,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 1,
      connectTimeout: 3000,
      retryStrategy: (times) => Math.min(times * 500, 5000),
    });
    this.client.on('ready', () => {
      this.warned = false;
      this.logger.log('Redis ulandi');
    });
    this.client.on('error', (e) => {
      if (!this.warned) {
        this.logger.warn(`Redis xatosi (kesh vaqtincha o‘chirildi): ${e.message}`);
        this.warned = true;
      }
    });
  }

  get ready(): boolean {
    return this.client?.status === 'ready';
  }

  async ping(): Promise<boolean> {
    if (!this.ready) return false;
    try {
      return (await this.client!.ping()) === 'PONG';
    } catch {
      return false;
    }
  }

  async get<T>(key: string): Promise<T | undefined> {
    if (!this.ready) return undefined;
    try {
      const raw = await this.client!.get(this.prefix + key);
      return raw == null ? undefined : (JSON.parse(raw) as T);
    } catch {
      return undefined;
    }
  }

  async set(key: string, value: unknown, ttlSeconds: number): Promise<void> {
    if (!this.ready) return;
    try {
      await this.client!.set(this.prefix + key, JSON.stringify(value), 'EX', ttlSeconds);
    } catch {
      /* kesh — ixtiyoriy */
    }
  }

  /** Keshdan oladi, bo'lmasa [load] ni chaqirib saqlaydi. */
  async wrap<T>(key: string, ttlSeconds: number, load: () => Promise<T>): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== undefined) return cached;
    const fresh = await load();
    await this.set(key, fresh, ttlSeconds);
    return fresh;
  }

  /** Prefiks bo'yicha o'chirish: del('book:') -> book:* */
  async del(...patterns: string[]): Promise<void> {
    if (!this.ready) return;
    try {
      for (const p of patterns) {
        const match = this.prefix + p + '*';
        let cursor = '0';
        do {
          const [next, keys] = await this.client!.scan(cursor, 'MATCH', match, 'COUNT', 200);
          cursor = next;
          if (keys.length) await this.client!.del(...keys);
        } while (cursor !== '0');
      }
    } catch {
      /* ignore */
    }
  }

  /**
   * Oddiy rate-limit: [windowSeconds] ichida [limit] dan oshsa false.
   * Redis yo'q bo'lsa — doim ruxsat.
   */
  async allow(key: string, limit: number, windowSeconds: number): Promise<boolean> {
    if (!this.ready) return true;
    try {
      const k = this.prefix + 'rl:' + key;
      const n = await this.client!.incr(k);
      if (n === 1) await this.client!.expire(k, windowSeconds);
      return n <= limit;
    } catch {
      return true;
    }
  }

  async onModuleDestroy() {
    await this.client?.quit().catch(() => undefined);
  }
}
