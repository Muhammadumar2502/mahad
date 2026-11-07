import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { RedisService } from 'src/_redis/redis.service';
import { CacheKeys } from 'src/_redis/redis.module';

@Injectable()
export class SubjectService {
  constructor(
    private readonly prisma: PrismaClientService,
    private readonly redis: RedisService,
  ) {}
  private logger = new Logger('Subject service');
  async create(data: CreateSubjectDto) {
    this.logger.log('create');
    const subject = await this.prisma.subject.create({
      data: {
        name: data.name,
        image: data.imgPath,
      },
    });
    return subject;
  }

  async findAll() {
    this.logger.log('findAll');
    return this.redis.wrap(CacheKeys.subjects, 300, () =>
      this.prisma.subject.findMany({ orderBy: { createdt: 'desc' } }),
    );
  }

  findOne(id: number) {
    return `This action returns a #${id} subject`;
  }

  async update(id: number, data: UpdateSubjectDto) {
    this.logger.log('update');

    let subject = await this.prisma.subject.findUnique({
      where: { id },
    });
    if (!subject) {
      throw new NotFoundException('subject not found');
    }

    return await this.prisma.subject.update({
      where: { id },
      data: {
        name: data.name,
        image: data.imgPath,
      },
    });
  }

  async remove(id: number) {
    this.logger.log('remove');
    let subject = await this.prisma.subject.findUnique({
      where: { id },
    });
    if (!subject) {
      throw new NotFoundException('subject not found');
    }

    return await this.prisma.subject.delete({
      where: { id },
    });
  }
}
