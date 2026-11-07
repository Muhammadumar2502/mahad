import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  FileTypeValidator,
  ParseFilePipe,
  HttpStatus,
  ParseFilePipeBuilder,
  UploadedFile,
  UseInterceptors,
  Req,
  UseGuards,
  Put,
} from '@nestjs/common';
import { SectionService } from './section.service';
import { CreateSectionDto } from './dto/create-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from 'src/_guard/auth.guard';
import { AdminGuard } from 'src/_guard/admin.guard';

@UseGuards(AuthGuard)
@Controller('section')
export class SectionController {
  constructor(private readonly sectionService: SectionService) {}

  @Post()
  @UseGuards(AdminGuard)
  @UseInterceptors(FileInterceptor('image'))
  create(
    @Body() createBookDto: CreateSectionDto,
    // @UploadedFile(
    //   new ParseFilePipeBuilder()
    //     .addMaxSizeValidator({
    //       maxSize: 5 * 1024 * 1024,
    //     })
    //     .build({
    //       errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
    //       fileIsRequired: false,
    //     }),
    //   new ParseFilePipe({
    //     validators: [
    //       new FileTypeValidator({ fileType: /(jpg|jpeg|png|webp)$/ }),
    //     ],
    //   }),
    // )
    // image: Express.Multer.File,
  ) {
    return this.sectionService.create(createBookDto);
  }

  @Get('/all')
  findAll(@Req() req: Request) {
    return this.sectionService.findAll(req);
  }

  @Get('/book/:bookId')
  findByBook(@Param('bookId') bookId: string) {
    return this.sectionService.findByBook(+bookId);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Req() req: Request) {
    return this.sectionService.findOne(+id, req);
  }

  @UseGuards(AdminGuard)
  @Put(':id')
  update(@Param('id') id: string, @Body() updateSectionDto: UpdateSectionDto) {
    return this.sectionService.update(+id, updateSectionDto);
  }

  @UseGuards(AdminGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.sectionService.remove(+id);
  }
}
