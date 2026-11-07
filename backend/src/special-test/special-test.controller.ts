import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
  Put,
} from '@nestjs/common';
import { SpecialTestService } from './special-test.service';
import { CreateSpecialTestDto } from './dto/create-special-test.dto';
import { UpdateSpecialTestDto } from './dto/update-special-test.dto';
import { SubmitSpecialTestDto } from './dto/submit-special-test.dto';
import { AuthGuard } from 'src/_guard/auth.guard';

@Controller('special-test')
@UseGuards(AuthGuard)
export class SpecialTestController {
  constructor(private readonly specialTestService: SpecialTestService) {}

  @Post()
  create(@Body() createSpecialTestDto: CreateSpecialTestDto, @Request() req) {
    return this.specialTestService.create(createSpecialTestDto, req.user);
  }

  @Get('all')
  findAll(@Request() req) {
    return this.specialTestService.findAll(req.user);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req) {
    return this.specialTestService.findOne(+id, req.user);
  }

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() updateSpecialTestDto: UpdateSpecialTestDto,
    @Request() req,
  ) {
    return this.specialTestService.update(+id, updateSpecialTestDto, req.user);
  }

  @Post(':id/submit')
  submit(
    @Param('id') id: string,
    @Body() submitDto: SubmitSpecialTestDto,
    @Request() req,
  ) {
    return this.specialTestService.submit(+id, submitDto, req.user);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req) {
    return this.specialTestService.remove(+id, req.user);
  }
}
