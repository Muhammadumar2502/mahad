import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { CreateResultDto } from './dto/create-result.dto';
import { UpdateResultDto } from './dto/update-result.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { Request } from 'express';
import { Role } from '@prisma/client';

@Injectable()
export class ResultService {
  constructor(private readonly prisma: PrismaClientService) {}
  private logger = new Logger('Result service');
  async create(data: CreateResultDto, req: Request) {
    this.logger.log('create');
    console.log(data.type);

    // Validate finish time if provided
    if (data.finishTime) {
      const finishTime = new Date(data.finishTime);
      const now = new Date();

      if (finishTime > now) {
        throw new BadRequestException('Test vaqti hali tugamagan');
      }
    }

    if (data.type != 'RANDOM') {
      let test = await this.prisma.test.findUnique({
        where: { id: data.test_id },
      });

      if (!test) {
        throw new NotFoundException('Test not found');
      }
    }
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    const result = await this.prisma.result.create({
      data: {
        ...data,
        student_id: user.id,
        startTime: data.startTime ? new Date(data.startTime) : undefined,
        finishTime: data.finishTime ? new Date(data.finishTime) : undefined,
      },
    });
    return result;
  }

  async findAll(req: Request) {
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    this.logger.log('findAll');
    const results = await this.prisma.result.findMany({
      where: {
        student_id: user.role == Role.STUDENT ? user.id : undefined,
      },
      orderBy: {
        id: 'desc',
      },

      include: {
        student: user.role == Role.ADMIN && {
          omit: { password: true },
          include: {
            group: true,
          },
        },
        test: {
          include: {
            _count: {
              select: { test_items: true, results: true },
            },
            section: {
              include: {
                book: {
                  include: {
                    subject: true,
                  },
                },
              },
            },
          },
        },
        specialTest: {
          include: {
            questions: true,
            specialTestGroups: {
              include: {
                group: true,
              },
            },
            specialTestSections: {
              include: {
                section: {
                  include: {
                    book: {
                      include: {
                        subject: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    return results;
  }

  findOne(id: number) {
    return `This action returns a #${id} result`;
  }

  update(id: number, updateResultDto: UpdateResultDto) {
    return `This action updates a #${id} result`;
  }

  remove(id: number) {
    return `This action removes a #${id} result`;
  }
}
