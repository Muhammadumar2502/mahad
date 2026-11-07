import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { PrismaClientService } from 'src/_prisma_client/prisma_client.service';

@Injectable()
export class GroupService {
  constructor(private readonly prisma: PrismaClientService) {}
  private logger = new Logger('Group service');
  async create(data: CreateGroupDto) {
    this.logger.log('create');
    const group = await this.prisma.group.create({
      data,
    });
    return group;
  }

  async findAll() {
    this.logger.log('findAll');
    const groups = await this.prisma.group.findMany({
      orderBy: {
        createdt: 'desc', // yoki id: 'desc'
      },
    });
    return groups;
  }

  async findOne(id: number) {
    this.logger.log('findOne');
    let group = await this.prisma.group.findUnique({
      where: { id },
    });
    if (!group) {
      throw new NotFoundException('group not found');
    }

    return group;
  }

  async update(id: number, data: UpdateGroupDto) {
    this.logger.log('update');

    let group = await this.prisma.group.findUnique({
      where: { id },
    });
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    return await this.prisma.group.update({
      where: { id },
      data,
    });
  }

  async remove(id: number) {
    this.logger.log('remove');
    let group = await this.prisma.group.findUnique({
      where: { id },
    });
    if (!group) {
      throw new NotFoundException('Group not found');
    }

    return await this.prisma.group.delete({
      where: { id },
    });
  }
}
