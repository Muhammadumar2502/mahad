import { Module } from '@nestjs/common';
import { SpecialTestService } from './special-test.service';
import { SpecialTestController } from './special-test.controller';
import { PrismaClientModule } from 'src/_prisma_client/prisma_client.module';

@Module({
  controllers: [SpecialTestController],
  providers: [SpecialTestService],
  imports: [PrismaClientModule],
})
export class SpecialTestModule {}
