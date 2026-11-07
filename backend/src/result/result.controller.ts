import { AdminGuard } from 'src/_guard/admin.guard';
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ResultService } from './result.service';
import { CreateResultDto } from './dto/create-result.dto';
import { UpdateResultDto } from './dto/update-result.dto';
import { AuthGuard } from 'src/_guard/auth.guard';

@UseGuards(AuthGuard)
@Controller('result')
export class ResultController {
  constructor(private readonly resultService: ResultService) {}

  @Post()
  create(@Body() createTestDto: CreateResultDto, @Req() req) {
    return this.resultService.create(createTestDto, req);
  }

  @Get('/all')
  findAll(@Req() req) {
    return this.resultService.findAll(req);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.resultService.findOne(+id);
  }

  @UseGuards(AdminGuard)

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateResultDto: UpdateResultDto) {
    return this.resultService.update(+id, updateResultDto);
  }

  @UseGuards(AdminGuard)

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.resultService.remove(+id);
  }
}
