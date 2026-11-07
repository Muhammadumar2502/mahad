import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateTestItemDto } from './dto/create-test-item.dto';
import { UpdateTestItemDto } from './dto/update-test-item.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { CreateMoreTestItemsDto } from './dto/create-more-test-item.dto';

@Injectable()
export class TestItemService {
  constructor(private readonly prisma: PrismaClientService) {}
  private logger = new Logger('Test-item service');
  async create(data: CreateTestItemDto) {
    this.logger.log('create');

    let test = await this.prisma.test.findUnique({
      where: { id: data.test_id },
      select: {
        test_items: true,
      },
    });
    data.number = test.test_items.length + 1;
    if (!test) {
      throw new NotFoundException('Test not found');
    }
    const testItem = await this.prisma.testItem.create({
      data,
    });
    return testItem;
  }

  async createMore(data: CreateMoreTestItemsDto) {
    this.logger.log('create-more');

    let section = await this.prisma.section.findUnique({
      where: { id: data.section_id },
      include: {
        test: {
          include: {
            test_items: true,
          },
        },
      },
    });

    if (!section) {
      throw new NotFoundException("Bo'lim topilmadi");
    }

    if (!section.test) {
      let test = await this.prisma.test.create({
        data: {
          section_id: data.section_id,
        },
      });

      await this.prisma.testItem.createMany({
        data: data.items.map((item) => ({
          question: item.question,
          test_id: test.id,
          number: item.number,
          answer: item.answer,
          answer_A: item.answer_A,
          answer_B: item.answer_B,
          answer_C: item.answer_C,
          answer_D: item.answer_D || '', // optional bo‘lsa default
        })),
      });

      return this.prisma.test.findUnique({
        where: {
          id: test.id,
        },
        include: {
          test_items: true,
        },
      });
    }

    // Test mavjud - test_items qo'shamiz
    await this.prisma.testItem.createMany({
      data: data.items.map((item) => ({
        question: item.question,
        test_id: section.test.id,
        number: item.number,
        answer: item.answer,
        answer_A: item.answer_A,
        answer_B: item.answer_B,
        answer_C: item.answer_C,
        answer_D: item.answer_D || '',
      })),
    });

    return this.prisma.test.findUnique({
      where: { id: section.test.id },
      include: { test_items: true },
    });
  }
  async findAll(test_id: string | undefined) {
    this.logger.log('findAll');
    console.log('test_id parameter:', test_id);
    console.log('test_id type:', typeof test_id);
    console.log('test_id length:', test_id?.length);

    // First, let's count all records to see if they exist
    const totalCount = await this.prisma.testItem.count();
    console.log('Total test items in database:', totalCount);

    // Handle empty string or undefined
    const whereClause =
      test_id && test_id.trim() !== '' ? { test_id: parseInt(test_id) } : {};
    console.log('whereClause:', whereClause);

    const testItems = await this.prisma.testItem.findMany({
      where: whereClause,
      orderBy: {
        createdt: 'desc', // yoki id: 'desc'
      },
    });

    console.log('Found test items count:', testItems.length);
    console.log('First few items:', testItems.slice(0, 3));

    return testItems;
  }

  findOne(id: number) {
    return `This action returns a #${id} testItem`;
  }

  async findByTestId(testId: number) {
    this.logger.log('findByTestId: ' + testId);
    const testItems = await this.prisma.testItem.findMany({
      where: { test_id: testId },
      orderBy: {
        number: 'asc',
      },
    });
    return testItems;
  }

  async removeByTestId(testId: number) {
    this.logger.log('removeByTestId: ' + testId);
    await this.prisma.testItem.deleteMany({
      where: { test_id: testId },
    });
    return { message: 'All test items deleted for test: ' + testId };
  }

  async updateMany(testId: number, items: any[]) {
    this.logger.log('updateMany for test: ' + testId);

    // Mavjud test_itemlarni olish
    const existingItems = await this.prisma.testItem.findMany({
      where: { test_id: testId },
      orderBy: { number: 'asc' },
    });

    // Kelgan itemlar soni va mavjud itemlar sonini taqqoslash
    const newCount = items.length;
    const existingCount = existingItems.length;

    // 1. Mavjud itemlarni update qilish yoki yangi yaratish
    const updatePromises = items.map((item, index) => {
      if (index < existingCount) {
        // Mavjud itemni update qilish
        return this.prisma.testItem.update({
          where: { id: existingItems[index].id },
          data: {
            question: item.question,
            number: item.number,
            answer: item.answer,
            answer_A: item.answer_A,
            answer_B: item.answer_B,
            answer_C: item.answer_C,
            answer_D: item.answer_D || '',
          },
        });
      } else {
        // Yangi item yaratish
        return this.prisma.testItem.create({
          data: {
            question: item.question,
            test_id: testId,
            number: item.number,
            answer: item.answer,
            answer_A: item.answer_A,
            answer_B: item.answer_B,
            answer_C: item.answer_C,
            answer_D: item.answer_D || '',
          },
        });
      }
    });

    await Promise.all(updatePromises);

    // 2. Ortiqcha itemlarni o'chirish (agar mavjud ko'p bo'lsa)
    if (existingCount > newCount) {
      const idsToDelete = existingItems.slice(newCount).map((item) => item.id);
      await this.prisma.testItem.deleteMany({
        where: { id: { in: idsToDelete } },
      });
    }

    // Yangilangan testni qaytarish
    return this.prisma.test.findUnique({
      where: { id: testId },
      include: { test_items: true },
    });
  }

  update(id: number, updateTestItemDto: UpdateTestItemDto) {
    return `This action updates a #${id} testItem`;
  }

  remove(id: number) {
    return `This action removes a #${id} testItem`;
  }
}
