import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateBookDto } from './dto/create-book.dto';
import { UpdateBookDto } from './dto/update-book.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { RedisService } from 'src/_redis/redis.service';
import { CacheKeys } from 'src/_redis/redis.module';

@Injectable()
export class BookService {
  constructor(
    private readonly prisma: PrismaClientService,
    private readonly redis: RedisService,
  ) {}
  private logger = new Logger('Book service');
  async create(data: CreateBookDto) {
    this.logger.log('create');

    let subject = await this.prisma.subject.findUnique({
      where: { id: parseInt(data.subject_id.toString()) },
    });
    console.log(subject);

    if (!subject) {
      throw new NotFoundException('Subject not found');
    }
    const book = await this.prisma.book.create({
      data: {
        name: data.name,
        subject_id: subject.id,
        image: data.imgPath,
        fullBlock: data.fullBlock,
        stepBlock: data.stepBlock,
        passingPercentage: data.passingPercentage || 60,
      },
    });
    return book;
  }

  async findAll() {
    this.logger.log('findAll');
    return this.redis.wrap(CacheKeys.books, 120, () =>
      this.prisma.book.findMany({
        orderBy: { createdt: 'desc' },
        include: { subject: true, sections: { orderBy: { id: 'asc' } } },
      }),
    );
  }

  async findOne(id: number) {
    const book = await this.prisma.book.findUnique({
      where: { id },
      include: {
        subject: true,
        sections: {
          orderBy: {
            id: 'asc',
          },
        },
      },
    });

    if (!book) {
      throw new NotFoundException('Book not found');
    }

    return book;
  }

  async update(id: number, data: UpdateBookDto) {
    console.log('📚 Update Book - Received data:', {
      id,
      name: data.name,
      subject_id: data.subject_id,
      imgPath: data.imgPath,
      fullBlock: data.fullBlock,
      typeof_fullBlock: typeof data.fullBlock,
      stepBlock: data.stepBlock,
      typeof_stepBlock: typeof data.stepBlock,
      passingPercentage: data.passingPercentage,
      typeof_passingPercentage: typeof data.passingPercentage,
    });

    if (data.subject_id) {
      let subject = await this.prisma.subject.findUnique({
        where: { id: +data.subject_id },
      });
      if (!subject) {
        throw new NotFoundException('subject not found');
      }
    }

    let book = await this.prisma.book.findUnique({
      where: { id },
    });
    if (!book) {
      throw new NotFoundException('book not found');
    }

    const updateData: any = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.subject_id !== undefined) updateData.subject_id = +data.subject_id;
    if (data.imgPath !== undefined) updateData.image = data.imgPath;
    if (data.fullBlock !== undefined) updateData.fullBlock = data.fullBlock;
    if (data.stepBlock !== undefined) updateData.stepBlock = data.stepBlock;
    if (data.passingPercentage !== undefined)
      updateData.passingPercentage = data.passingPercentage;

    console.log('💾 Update Book - Data to save:', updateData);

    const updatedBook = await this.prisma.book.update({
      where: { id },
      data: updateData,
    });

    console.log('✅ Update Book - Saved result:', {
      id: updatedBook.id,
      name: updatedBook.name,
      fullBlock: updatedBook.fullBlock,
      stepBlock: updatedBook.stepBlock,
      passingPercentage: updatedBook.passingPercentage,
    });

    return updatedBook;
  }

  async remove(id: number) {
    let group = await this.prisma.book.findUnique({
      where: { id },
    });
    if (!group) {
      throw new NotFoundException('book not found');
    }

    return await this.prisma.book.delete({
      where: { id },
    });
  }
}
