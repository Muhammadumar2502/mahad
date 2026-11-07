import { AdminGuard } from 'src/_guard/admin.guard';
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
  UseInterceptors,
  HttpStatus,
  ParseFilePipe,
  FileTypeValidator,
  UseGuards,
  Put,
} from '@nestjs/common';
import { BookService } from './book.service';
import { CreateBookDto } from './dto/create-book.dto';
import { UpdateBookDto } from './dto/update-book.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from 'src/_guard/auth.guard';

@UseGuards(AuthGuard)
@Controller('book')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @UseGuards(AdminGuard)

  @Post()
  @UseInterceptors(FileInterceptor('image'))
  create(
    @Body() createBookDto: CreateBookDto,
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
    return this.bookService.create(createBookDto);
  }

  @Get('/all')
  findAll() {
    return this.bookService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.bookService.findOne(+id);
  }

  @UseGuards(AdminGuard)

  @Put(':id')
  @UseInterceptors(FileInterceptor('image'))
  update(@Param('id') id: string, @Body() updateBookDto: UpdateBookDto) {
    return this.bookService.update(+id, updateBookDto);
  }

  @UseGuards(AdminGuard)

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.bookService.remove(+id);
  }
}
