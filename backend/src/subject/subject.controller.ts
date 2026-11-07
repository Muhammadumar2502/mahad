import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UploadedFile,
  ParseFilePipeBuilder,
  HttpStatus,
  UseInterceptors,
  ParseFilePipe,
  FileTypeValidator,
  UseGuards,
  Put,
} from '@nestjs/common';
import { SubjectService } from './subject.service';
import { CreateSubjectDto } from './dto/create-subject.dto';
import { UpdateSubjectDto } from './dto/update-subject.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from 'src/_guard/auth.guard';
import { AdminGuard } from 'src/_guard/admin.guard';

@UseGuards(AuthGuard)
@Controller('subject')
export class SubjectController {
  constructor(private readonly subjectService: SubjectService) {}

  @UseGuards(AdminGuard)
  @Post()
  @UseInterceptors(FileInterceptor('image'))
  create(@Body() createSubjectDto: CreateSubjectDto) {
    return this.subjectService.create(createSubjectDto);
  }

  @Get('/all')
  findAll() {
    return this.subjectService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.subjectService.findOne(+id);
  }

  @UseGuards(AdminGuard)
  @Put(':id')
  @UseInterceptors(FileInterceptor('image'))
  update(@Param('id') id: string, @Body() updateSubjectDto: UpdateSubjectDto) {
    return this.subjectService.update(+id, updateSubjectDto);
  }

  @UseGuards(AdminGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.subjectService.remove(+id);
  }
}
