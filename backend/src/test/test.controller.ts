import { AdminGuard } from 'src/_guard/admin.guard';
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpStatus,
  FileTypeValidator,
  ParseFilePipe,
  ParseFilePipeBuilder,
  UploadedFile,
  UseInterceptors,
  UseGuards,
  HttpCode,
} from '@nestjs/common';
import { TestService } from './test.service';
import { CreateTestDto } from './dto/create-test.dto';
import { UpdateTestDto } from './dto/update-test.dto';
import { AuthGuard } from 'src/_guard/auth.guard';
import { RandomTestDto } from './dto/random-test.dto';

@UseGuards(AuthGuard)
@Controller('test')
export class TestController {
  constructor(private readonly testService: TestService) {}

  @UseGuards(AdminGuard)

  @Post()
  create(@Body() createTestDto: CreateTestDto) {
    return this.testService.create(createTestDto);
  }

  @Post('/random')
  @HttpCode(HttpStatus.OK)
  random(@Body() randomTestDto: RandomTestDto) {
    return this.testService.random(randomTestDto);
  }

  @Get('/all')
  findAll() {
    return this.testService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.testService.findOne(+id);
  }

  @UseGuards(AdminGuard)

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTestDto: UpdateTestDto) {
    return this.testService.update(+id, updateTestDto);
  }

  @UseGuards(AdminGuard)

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.testService.remove(+id);
  }
}
