import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { CreateSectionDto } from './dto/create-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { RedisService } from 'src/_redis/redis.service';
import { CacheKeys } from 'src/_redis/redis.module';
import { Role } from '@prisma/client';

@Injectable()
export class SectionService {
  constructor(
    private readonly prisma: PrismaClientService,
    private readonly redis: RedisService,
  ) {}
  private logger = new Logger('Section service');
  async create(data: CreateSectionDto) {
    this.logger.log('create');

    let book = await this.prisma.book.findUnique({
      where: { id: parseInt(data.book_id.toString()) },
    });
    console.log(book);

    if (!book) {
      throw new NotFoundException('Book not found');
    }
    const section = await this.prisma.section.create({
      data: {
        name: data.name,
        book_id: book.id,
        image: data.imgPath,
      },
    });
    return section;
  }

  async findAll(req: Request) {
    this.logger.log('findAll');
    this.logger.log('findOne');
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    // const student = await this.prisma.student.findUnique({
    //   where: { id: user.id },
    // });

    // const bookGroups = await this.prisma.bookGroup.findMany({
    //   where: {
    //     groupId: student.group_id,
    //   },
    //   include: { book: true }
    // });

    // await this.prisma.book.update({
    //   where: { id: 4 },
    //   data: {
    //     bookGroups : {
    //       connect :{

    //         bookId_groupId :{
    //           groupId : 1,
    //           bookId  : 4
    //         }
    //       }
    //     }
    //   }
    // });

    if (user.role == Role.ADMIN) {
      const sections = await this.prisma.section.findMany({
        // where: {
        //   book: {
        //     bookGroups : {
        //       some : {
        //         groupId :  student.group_id,
        //       }
        //     }
        //   },
        // },

        orderBy: {
          createdt: 'desc', // yoki id: 'desc'
        },

        include: {
          book: true,
          test: {
            include: {
              _count: {
                select: { test_items: true },
              },
            },
          },
        },
      });
      return sections;
    } else {
      const sections = await this.prisma.section.findMany({
        // where: {
        //   book: {
        //     bookGroups : {
        //       some : {
        //         groupId :  student.group_id,
        //       }
        //     }
        //   },
        // },

        orderBy: {
          createdt: 'desc', // yoki id: 'desc'
        },

        include: {
          book: true,
          test: {
            include: {
              results: {
                where: { student_id: user.id },
              },

              _count: {
                select: { test_items: true, results: true },
              },
            },
          },
        },
      });
      return sections;
    }
  }
  async findOne(id: number, req: Request) {
    this.logger.log('findOne');
    let user: {
      role: Role | undefined;
      id: number | undefined;
    } = req['user'];

    let section = await this.prisma.section.findUnique({
      where: { id },
      include: {
        book: {
          include: {
            subject: true,
            sections: {
              orderBy: {
                id: 'asc',
              },
            },
          },
        },
        test: {
          include: {
            _count: {
              select: { test_items: true, results: true },
            },
            results: {
              where: { student_id: user.id },
              orderBy: {
                id: 'desc',
              },
            },
          },
        },
      },
    });
    if (!section) {
      throw new NotFoundException('section not found');
    }

    // Check if stepBlock is enabled and user is a student
    let isBlocked = false;
    let blockReason = '';
    
    if (user.role === Role.STUDENT && section.book?.stepBlock) {
      const allSections = section.book.sections;
      const currentSectionIndex = allSections.findIndex(
        (s) => s.id === section.id,
      );

      // If not the first section, check if previous section was passed with required percentage
      if (currentSectionIndex > 0) {
        const previousSection = allSections[currentSectionIndex - 1];

        // Get previous section with test and ALL results
        const previousSectionWithTest = await this.prisma.section.findUnique({
          where: { id: previousSection.id },
          include: {
            test: {
              include: {
                _count: {
                  select: { test_items: true },
                },
                results: {
                  where: { student_id: user.id },
                  orderBy: {
                    id: 'desc',
                  },
                },
              },
            },
          },
        });

        // If previous section has a test
        if (previousSectionWithTest?.test) {
          const allResults = previousSectionWithTest.test.results;
          const totalQuestions = previousSectionWithTest.test._count.test_items;

          // If no result found, mark as blocked
          if (!allResults || allResults.length === 0) {
            isBlocked = true;
            blockReason = `Oldingi bo'limni (${previousSection.name}) tugatishingiz kerak`;
          } else {
            // Find the maximum score from all attempts
            let maxPercentage = 0;
            for (const result of allResults) {
              const percentage =
                totalQuestions > 0 ? ((result.solved ?? 0) / totalQuestions) * 100 : 0;
              if (percentage > maxPercentage) {
                maxPercentage = percentage;
              }
            }

            const requiredPercentage = section.book.passingPercentage || 60;

            // If max percentage is less than required, mark as blocked
            if (maxPercentage < requiredPercentage) {
              isBlocked = true;
              blockReason = `Oldingi bo'limni kamida ${requiredPercentage}% natija bilan tugatishingiz kerak. Sizning eng yuqori natijangiz: ${maxPercentage.toFixed(1)}%`;
            }
          }
        }
      }
    }

    return {
      ...section,
      isBlocked,
      blockReason,
    };
  }

  async findByBook(bookId: number) {
    this.logger.log('findByBook');
    return this.redis.wrap(CacheKeys.sectionsByBook(bookId), 120, () => this.prisma.section.findMany({
      where: { book_id: bookId },
      orderBy: {
        id: 'asc',
      },
      include: {
        test: {
          include: {
            _count: {
              select: { test_items: true },
            },
          },
        },
      },
    }));
  }

  async update(id: number, data: UpdateSectionDto) {
    if (data.book_id) {
      let book = await this.prisma.book.findUnique({
        where: { id: +data.book_id },
      });
      if (!book) {
        throw new NotFoundException('book not found');
      }
    }

    let section = await this.prisma.section.findUnique({
      where: { id },
    });
    if (!section) {
      throw new NotFoundException('section not found');
    }

    return await this.prisma.section.update({
      where: { id },
      data: {
        name: data.name,
        book_id: data.book_id ? +data.book_id : undefined,
      },
    });
  }

  async remove(id: number) {
    let section = await this.prisma.section.findUnique({
      where: { id },
    });
    if (!section) {
      throw new NotFoundException('section not found');
    }

    return await this.prisma.section.delete({
      where: { id },
    });
  }
}
