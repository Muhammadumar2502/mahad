import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { CreateSpecialTestDto } from './dto/create-special-test.dto';
import { UpdateSpecialTestDto } from './dto/update-special-test.dto';
import { SubmitSpecialTestDto } from './dto/submit-special-test.dto';
import {
  SpecialTestResponseDto,
  SpecialTestQuestionResponseDto,
} from './dto/special-test-response.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';
import { ConflictException } from '@nestjs/common';

@Injectable()
export class SpecialTestService {
  constructor(private readonly prisma: PrismaClientService) {}
  private logger = new Logger('SpecialTest service');

  private transformSpecialTest(specialTest: any): SpecialTestResponseDto {
    return {
      id: specialTest.id,
      name: specialTest.name,
      description: specialTest.description,
      subject_id: specialTest.subject_id,
      book_ids: specialTest.specialTestBooks?.map((stb) => stb.bookId) || [],
      section_ids:
        specialTest.specialTestSections?.map((sts) => sts.sectionId) || [],
      group_ids: specialTest.specialTestGroups?.map((stg) => stg.groupId) || [],
      activation_start: specialTest.activation_start?.toISOString(),
      activation_end: specialTest.activation_end?.toISOString(),
      time_per_question: specialTest.time_per_question,
      total_time: specialTest.total_time,
      force_next_question: specialTest.force_next_question,
      question_count: specialTest.question_count,
      questions:
        specialTest.questions?.map((q) => ({
          id: q.id,
          number: q.number,
          question: q.question.replace(/^\d+\.\s*/, ''),
          answer_A: q.answer_A,
          answer_B: q.answer_B,
          answer_C: q.answer_C,
          answer_D: q.answer_D,
          answer: q.answer,
        })) || [],
      createdAt: specialTest.createdAt?.toISOString(),
      updatedAt: specialTest.updatedAt?.toISOString(),
    };
  }

  async create(data: CreateSpecialTestDto, user: any) {
    this.logger.log('create special test');

    // Check if user is admin
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Only admins can create special tests');
    }

    // Validate that exactly one of time_per_question or total_time is provided
    if (
      (data.time_per_question && data.total_time) ||
      (!data.time_per_question && !data.total_time)
    ) {
      throw new ForbiddenException(
        'Either time_per_question or total_time must be provided, but not both',
      );
    }

    // Validate subject exists
    const subject = await this.prisma.subject.findUnique({
      where: { id: data.subject_id },
    });
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    // Validate book exists (if provided)
    if (data.book_ids && data.book_ids.length > 0) {
      const books = await this.prisma.book.findMany({
        where: { id: { in: data.book_ids } },
      });
      if (books.length !== data.book_ids.length) {
        throw new NotFoundException('One or more books not found');
      }
    }

    // Validate sections exist (if provided)
    if (data.section_ids && data.section_ids.length > 0) {
      const sections = await this.prisma.section.findMany({
        where: { id: { in: data.section_ids } },
      });
      if (sections.length !== data.section_ids.length) {
        throw new NotFoundException('One or more sections not found');
      }
    }

    // Validate groups exist (if provided)
    if (data.group_ids && data.group_ids.length > 0) {
      const groups = await this.prisma.group.findMany({
        where: { id: { in: data.group_ids } },
      });
      if (groups.length !== data.group_ids.length) {
        throw new NotFoundException('One or more groups not found');
      }
    }

    // Create special test with questions and relations
    const timeData = data.time_per_question
      ? { time_per_question: data.time_per_question, total_time: null }
      : { total_time: data.total_time, time_per_question: null };

    const specialTest = await this.prisma.specialTest.create({
      data: {
        name: data.name,
        description: data.description,
        subject_id: data.subject_id,
        activation_start: data.activation_start
          ? new Date(data.activation_start)
          : null,
        activation_end: data.activation_end
          ? new Date(data.activation_end)
          : null,
        ...timeData,
        force_next_question: data.force_next_question || false,
        question_count: data.question_count,
        questions: {
          create: data.questions.map((q) => ({
            number: q.number,
            question: q.question,
            answer_A: q.answer_A,
            answer_B: q.answer_B,
            answer_C: q.answer_C,
            answer_D: q.answer_D,
            answer: q.answer,
          })),
        },
        ...(data.book_ids &&
          data.book_ids.length > 0 && {
            specialTestBooks: {
              create: data.book_ids.map((bookId) => ({
                bookId: bookId,
              })),
            },
          }),
        ...(data.group_ids &&
          data.group_ids.length > 0 && {
            specialTestGroups: {
              create: data.group_ids.map((groupId) => ({
                groupId: groupId,
              })),
            },
          }),
        ...(data.section_ids &&
          data.section_ids.length > 0 && {
            specialTestSections: {
              create: data.section_ids.map((sectionId) => ({
                sectionId: sectionId,
              })),
            },
          }),
      },
      include: {
        questions: true,
        specialTestBooks: {
          include: {
            book: true,
          },
        },
        specialTestGroups: {
          include: {
            group: true,
          },
        },
        specialTestSections: {
          include: {
            section: true,
          },
        },
      },
    });

    return this.transformSpecialTest(specialTest);
  }

  private hideAnswers(dto: SpecialTestResponseDto): SpecialTestResponseDto {
    return {
      ...dto,
      questions: dto.questions.map((q) => ({ ...q, answer: '' })),
    };
  }

  async findAll(user: any) {
    this.logger.log('findAll special tests');

    if (user.role === 'ADMIN') {
      // Admin sees all special tests
      const specialTests = await this.prisma.specialTest.findMany({
        include: {
          questions: true,
          specialTestBooks: {
            include: {
              book: true,
            },
          },
          specialTestGroups: {
            include: {
              group: true,
            },
          },
          specialTestSections: {
            include: {
              section: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });
      return specialTests.map((st) => this.transformSpecialTest(st));
    } else if (user.role === 'STUDENT') {
      // Student sees only special tests for their group (vaqtincha filtersiz)
      const specialTests = await this.prisma.specialTest.findMany({
        where: {
          specialTestGroups: {
            some: {
              groupId: user.group_id,
            },
          },
          // Vaqtincha date filtrini o'chirib qo'ydik
          // activation_start: {
          //   lte: new Date(),
          // },
          // activation_end: {
          //   gte: new Date(),
          // },
        },
        include: {
          questions: true,
          specialTestBooks: {
            include: {
              book: true,
            },
          },
          specialTestGroups: {
            include: {
              group: true,
            },
          },
          specialTestSections: {
            include: {
              section: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      // Check which tests student has attempted
      const results = await this.prisma.result.findMany({
        where: {
          student_id: user.id,
          special_test_id: {
            in: specialTests.map((st) => st.id),
          },
        },
        select: {
          special_test_id: true,
        },
      });

      const attemptedTestIds = new Set(results.map((r) => r.special_test_id));

      // O'quvchiga to'g'ri javoblar yuborilmaydi — ular faqat topshirgandan keyin qaytadi.
      return specialTests.map((st) => ({
        ...this.hideAnswers(this.transformSpecialTest(st)),
        has_attempted: attemptedTestIds.has(st.id),
      }));
    } else {
      throw new ForbiddenException('Access denied');
    }
  }

  async findOne(id: number, user: any) {
    this.logger.log(`findOne special test ${id}`);

    const specialTest = await this.prisma.specialTest.findUnique({
      where: { id },
      include: {
        questions: {
          orderBy: {
            number: 'asc',
          },
        },
        specialTestBooks: {
          include: {
            book: true,
          },
        },
        specialTestGroups: {
          include: {
            group: true,
          },
        },
        specialTestSections: {
          include: {
            section: true,
          },
        },
      },
    });

    if (!specialTest) {
      throw new NotFoundException('Special test not found');
    }

    // Check access permissions
    if (user.role === 'STUDENT') {
      const hasAccess = specialTest.specialTestGroups.some(
        (stg) => stg.groupId === user.group_id,
      );
      if (!hasAccess) {
        throw new ForbiddenException('Access denied');
      }

      // Check if test is active (only if activation dates are set)
      if (specialTest.activation_start && specialTest.activation_end) {
        const now = new Date();
        if (
          now < specialTest.activation_start ||
          now > specialTest.activation_end
        ) {
          throw new ForbiddenException('Test is not active');
        }
      }

      const attempted = await this.prisma.result.findFirst({
        where: { student_id: user.id, special_test_id: id },
        select: { id: true },
      });
      return {
        ...this.hideAnswers(this.transformSpecialTest(specialTest)),
        has_attempted: !!attempted,
      };
    }

    return this.transformSpecialTest(specialTest);
  }

  async update(id: number, data: UpdateSpecialTestDto, user: any) {
    this.logger.log(`update special test ${id}`);

    // Check if user is admin
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Only admins can update special tests');
    }

    const specialTest = await this.prisma.specialTest.findUnique({
      where: { id },
    });

    if (!specialTest) {
      throw new NotFoundException('Special test not found');
    }

    // Update special test
    const updatedTest = await this.prisma.specialTest.update({
      where: { id },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.description !== undefined && {
          description: data.description,
        }),
        ...(data.subject_id && { subject_id: data.subject_id }),
        ...(data.activation_start && {
          activation_start: new Date(data.activation_start),
        }),
        ...(data.activation_end && {
          activation_end: new Date(data.activation_end),
        }),
        ...(data.time_per_question !== undefined && {
          time_per_question: data.time_per_question,
        }),
        ...(data.total_time !== undefined && { total_time: data.total_time }),
        ...(data.force_next_question !== undefined && {
          force_next_question: data.force_next_question,
        }),
        ...(data.question_count && { question_count: data.question_count }),
        ...(data.questions && {
          questions: {
            deleteMany: {},
            create: data.questions.map((q) => ({
              number: q.number,
              question: q.question,
              answer_A: q.answer_A,
              answer_B: q.answer_B,
              answer_C: q.answer_C,
              answer_D: q.answer_D,
              answer: q.answer,
            })),
          },
        }),
        ...(data.book_ids && {
          specialTestBooks: {
            deleteMany: {},
            create: data.book_ids.map((bookId) => ({
              bookId: bookId,
            })),
          },
        }),
        ...(data.group_ids && {
          specialTestGroups: {
            deleteMany: {},
            create: data.group_ids.map((groupId) => ({
              groupId: groupId,
            })),
          },
        }),
        ...(data.section_ids && {
          specialTestSections: {
            deleteMany: {},
            create: data.section_ids.map((sectionId) => ({
              sectionId: sectionId,
            })),
          },
        }),
      },
      include: {
        questions: true,
        specialTestBooks: {
          include: {
            book: true,
          },
        },
        specialTestGroups: {
          include: {
            group: true,
          },
        },
        specialTestSections: {
          include: {
            section: true,
          },
        },
      },
    });

    return this.transformSpecialTest(updatedTest);
  }

  async remove(id: number, user: any) {
    this.logger.log(`remove special test ${id}`);

    // Check if user is admin
    if (user.role !== 'ADMIN') {
      throw new ForbiddenException('Only admins can delete special tests');
    }

    const specialTest = await this.prisma.specialTest.findUnique({
      where: { id },
    });

    if (!specialTest) {
      throw new NotFoundException('Special test not found');
    }

    // Delete related junction records first
    await this.prisma.specialTestGroup.deleteMany({
      where: { specialTestId: id },
    });

    // Delete all related data first
    await this.prisma.result.deleteMany({
      where: {
        specialTest: {
          id: id,
        },
      },
    });

    await this.prisma.specialTestGroup.deleteMany({
      where: { specialTestId: id },
    });

    await this.prisma.specialTestBook.deleteMany({
      where: { specialTestId: id },
    });

    await this.prisma.specialTestSection.deleteMany({
      where: { specialTestId: id },
    });

    await this.prisma.specialTestQuestion.deleteMany({
      where: { specialTestId: id },
    });

    await this.prisma.specialTest.delete({
      where: { id },
    });

    return { message: 'Special test deleted successfully' };
  }

  async submit(id: number, data: SubmitSpecialTestDto, user: any) {
    this.logger.log(`submit special test ${id} by student ${user.id}`);

    // Check if user is student
    if (user.role !== 'STUDENT') {
      throw new ForbiddenException('Only students can submit special tests');
    }

    const specialTest = await this.prisma.specialTest.findUnique({
      where: { id },
      include: {
        questions: true,
        specialTestGroups: true,
        specialTestSections: true,
      },
    });

    if (!specialTest) {
      throw new NotFoundException('Special test not found');
    }

    // Check if test is active
    if (specialTest.activation_start && specialTest.activation_end) {
      const now = new Date();
      if (
        now < specialTest.activation_start ||
        now > specialTest.activation_end
      ) {
        throw new ForbiddenException('Test is not active');
      }
    }

    // Check access
    const hasAccess = specialTest.specialTestGroups.some(
      (stg) => stg.groupId === user.group_id,
    );
    if (!hasAccess) {
      throw new ForbiddenException('Access denied');
    }

    // Bir o'quvchi maxsus testni faqat bir marta topshiradi.
    const already = await this.prisma.result.findFirst({
      where: { student_id: user.id, special_test_id: id },
      select: { id: true },
    });
    if (already) {
      throw new ConflictException('Siz bu testni allaqachon topshirgansiz');
    }

    // Validate answers
    const questionIds = specialTest.questions.map((q) => q.id.toString());
    const submittedIds = Object.keys(data.answers);
    if (
      submittedIds.length !== questionIds.length ||
      !submittedIds.every((id) => questionIds.includes(id))
    ) {
      throw new ForbiddenException('All questions must be answered');
    }

    // Calculate solved (correct answers)
    let solvedCount = 0;
    for (const question of specialTest.questions) {
      const submittedAnswer = data.answers[question.id.toString()];
      if (submittedAnswer === question.answer) {
        solvedCount++;
      }
    }

    // Save result
    const result = await this.prisma.result.create({
      data: {
        student: {
          connect: { id: user.id },
        },
        specialTest: {
          connect: { id },
        },
        answers: data.answers,
        solved: solvedCount,
        type: 'SpecialTest',
      },
    });

    return {
      message: 'Special test submitted successfully',
      result_id: result.id,
      solved: solvedCount,
      total: specialTest.questions.length,
      // Topshirgandan keyin javoblarni ko'rib chiqish uchun kalit.
      answers_key: Object.fromEntries(
        specialTest.questions.map((q) => [q.id.toString(), q.answer]),
      ),
    };
  }
}
