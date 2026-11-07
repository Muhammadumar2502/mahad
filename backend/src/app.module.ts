import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AppLoggerMiddleware } from './_middlewares/logger-handler';
import { AuthModule } from './auth/auth.module';
import { JwtModule } from '@nestjs/jwt';
import { PrismaClientModule } from './_prisma_client/prisma_client.module';
import { ConfigModule } from '@nestjs/config';
import { StudentModule } from './student/student.module';
import { ResultModule } from './result/result.module';
import { SubjectModule } from './subject/subject.module';
import { TeacherModule } from './teacher/teacher.module';
import { AdminModule } from './admin/admin.module';
import { SectionModule } from './section/section.module';
import { GroupModule } from './group/group.module';
import { BookModule } from './book/book.module';
import { TestModule } from './test/test.module';
import { TestItemModule } from './test-item/test-item.module';
import { SpecialTestModule } from './special-test/special-test.module';
import { DeviceModule } from './device/device.module';
import { RedisModule } from './_redis/redis.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: '.env',
    }),
    JwtModule.register({
      global: true,
      secret: process.env.JWT_SECRET!,
      signOptions: { expiresIn: process.env.JWT_EXPIRES as any },
    }),

    RedisModule,
    AuthModule,
    PrismaClientModule,
    StudentModule,
    GroupModule,
    ResultModule,
    BookModule,
    SubjectModule,
    TestModule,
    TeacherModule,
    AdminModule,
    SectionModule,
    TestItemModule,
    SpecialTestModule,
    DeviceModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AppLoggerMiddleware).forRoutes('*');
  }
}
