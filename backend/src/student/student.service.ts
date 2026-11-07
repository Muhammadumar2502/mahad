import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { CreateStudentDto } from './dto/create-student.dto';
import { UpdateStudentDto } from './dto/update-student.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { generatePassword } from 'src/_utils/number.gen';
import { RedisService } from 'src/_redis/redis.service';
import { CacheKeys } from 'src/_redis/redis.module';
import { Result, Role } from '@prisma/client';

@Injectable()
export class StudentService {
  constructor(
    private readonly prisma: PrismaClientService,
    private readonly redis: RedisService,
  ) {}
  private logger = new Logger('Student service');
  async create(data: CreateStudentDto) {
    this.logger.log('create');
    let student = await this.prisma.student.findUnique({
      where: { phone: data.phone },
    });
    if (student) {
      throw new BadRequestException('This phone is used');
    }

    // Agar parol berilmagan yoki bo'sh bo'lsa, yangi parol generate qilish
    if (!data.password || data.password.trim() === '') {
      data.password = generatePassword({
        length: 8,
      });
    }

    student = await this.prisma.student.create({
      data: {
        name: data.name,
        phone: data.phone,
        password: data.password,
        group_id: data.group_id,
      },
    });
    return student;
  }

  async findAll() {
    this.logger.log('findAll');
    const students = await this.prisma.student.findMany({
      orderBy: {
        createdt: 'desc', // yoki id: 'desc'
      },
      include: {
        group: true,
      },
    });
    return students;
  }

  async rate(req: Request) {
    this.logger.log('rate');
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    let student = await this.prisma.student.findUnique({
      where: {
        id: user.id,
      },
    });

    if (!student) {
      throw new NotFoundException('Student not found');
    }

    // Get students from the same group
    let whereCondition: any = {};

    if (user.role === Role.ADMIN && student.group_id) {
      // If admin, show all students from the same group
      whereCondition.group_id = student.group_id;
    } else if (student.group_id) {
      // If student, show students from their group
      whereCondition.group_id = student.group_id;
    }

    return this.redis.wrap(CacheKeys.rate(student.group_id), 30, () => this.prisma.student.findMany({
      where: whereCondition,
      // Parollar hech qachon boshqa o'quvchilarga yuborilmaydi!
      omit: { password: true },
      orderBy: {
        createdt: 'desc',
      },
      include: {
        group: true,
        results: {
          include: {
            test: {
              include: {
                section: {
                  select: {
                    id: true,
                    name: true,
                    book_id: true,
                  },
                },
                _count: {
                  select: {
                    test_items: true,
                  },
                },
              },
            },
            specialTest: {
              include: {
                specialTestGroups: {
                  where: {
                    groupId: student.group_id || undefined,
                  },
                },
              },
            },
          },
        },
      },
    }));
  }

  async findOne(id: number) {
    this.logger.log('findOne');
    let student = await this.prisma.student.findUnique({
      where: { id },
      include: {
        group: true,
      },
    });
    if (!student) {
      throw new NotFoundException('Admin not found');
    }

    return student;
  }

  async update(id: number, data: UpdateStudentDto) {
    this.logger.log('update');
    console.log(data);

    let student = await this.prisma.student.findUnique({
      where: { id },
    });
    if (!student) {
      throw new NotFoundException('Admin not found');
    }

    return await this.prisma.student.update({
      where: { id },
      data,
    });
  }

  async remove(id: number) {
    this.logger.log('remove');
    let student = await this.prisma.student.findUnique({
      where: { id },
    });
    if (!student) {
      throw new NotFoundException('Admin not found');
    }

    return await this.prisma.student.delete({
      where: { id },
    });
  }

  async getMyGroup(req: Request) {
    this.logger.log('getMyGroup');
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    const student = await this.redis.wrap(CacheKeys.myGroup(user.id!), 60, () =>
      this.prisma.student.findUnique({
        where: { id: user.id },
        omit: { password: true },
        include: { group: true },
      }),
    );

    if (!student) {
      throw new NotFoundException('Student not found');
    }

    if (!student.group) {
      throw new NotFoundException('Student has no group assigned');
    }

    return student.group;
  }
}
