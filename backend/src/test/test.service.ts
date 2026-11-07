import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateTestDto } from './dto/create-test.dto';
import { UpdateTestDto } from './dto/update-test.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { CreateSectionDto } from 'src/section/dto/create-section.dto';
import { RandomTestDto } from './dto/random-test.dto';
import { v4 as uuidv4 } from 'uuid';
import { Prisma } from '@prisma/client';

@Injectable()
export class TestService {
  constructor(private readonly prisma: PrismaClientService) {}
  private logger = new Logger('Test service');
  async create(data: CreateTestDto) {
    this.logger.log('create');

    const test = await this.prisma.test.create({
      data: {
        name: data.name,
      },
    });
    return test;
  }

  async findAll() {
    this.logger.log('findAll');
    const tests = await this.prisma.test.findMany({
      include: {
        _count: {
          select: { test_items: true, results: true },
        },
        test_items: true,
        section: {
          include: {
            book: true,
          },
        },
      },

      orderBy: {
        createdt: 'desc', // yoki id: 'desc'
      },
    });
    return tests;
  }

  async findOne(id: number) {
    this.logger.log('findOne');
    const test = await this.prisma.test.findUnique({
      where: { id },
      include: {
        test_items: true,
        _count: {
          select: { test_items: true, results: true },
        },
      },
    });
    return test;
  }

  async update(id: number, updateTestDto: UpdateTestDto) {
    this.logger.log('update test id: ' + id);

    const test = await this.prisma.test.findUnique({
      where: { id },
    });

    if (!test) {
      throw new NotFoundException('Test not found');
    }

    const updatedTest = await this.prisma.test.update({
      where: { id },
      data: {
        name: updateTestDto.name,
      },
      include: {
        test_items: true,
      },
    });

    return updatedTest;
  }

  async remove(id: number) {
    this.logger.log('remove test id: ' + id);

    const test = await this.prisma.test.findUnique({
      where: { id },
    });

    if (!test) {
      throw new NotFoundException('Test not found');
    }

    // Avval test_items ni o'chirish
    await this.prisma.testItem.deleteMany({
      where: { test_id: id },
    });

    // Keyin testni o'chirish
    await this.prisma.test.delete({
      where: { id },
    });

    return { message: 'Test successfully deleted' };
  }

  async random(data: RandomTestDto) {
    const items = await this.prisma.$queryRaw`
  SELECT * FROM (
    SELECT DISTINCT TestItem.id
    FROM TestItem
    JOIN Test ON TestItem.test_id = Test.id
    WHERE Test.section_id IN (${Prisma.join(data.sections)})
    ORDER BY RAND()
    LIMIT ${data.count}
  ) AS t
  JOIN TestItem ON TestItem.id = t.id;
`;
    return {
      id: uuidv4(),
      data: items,
    };
  }
}
