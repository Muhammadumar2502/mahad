import { Global, Module } from '@nestjs/common';
import { RedisService } from './redis.service';

@Global()
@Module({
  providers: [RedisService],
  exports: [RedisService],
})
export class RedisModule {}

/** Kesh kalitlari va ularni tozalash guruhlari — bir joyda. */
export const CacheKeys = {
  subjects: 'subject:all',
  books: 'book:all',
  book: (id: number) => `book:${id}`,
  sectionsByBook: (id: number) => `section:book:${id}`,
  rate: (groupId: number | null) => `rate:group:${groupId ?? 'none'}`,
  myGroup: (studentId: number) => `group:student:${studentId}`,
};

/** Kontent o'zgarganda tozalanadigan prefikslar. */
export const ContentPrefixes = ['subject:', 'book:', 'section:'];
