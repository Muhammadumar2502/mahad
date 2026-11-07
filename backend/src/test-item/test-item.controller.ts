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
  Query,
  UseGuards,
} from '@nestjs/common';
import { TestItemService } from './test-item.service';
import { CreateTestItemDto } from './dto/create-test-item.dto';
import { UpdateTestItemDto } from './dto/update-test-item.dto';
import { AuthGuard } from 'src/_guard/auth.guard';
import { CreateMoreTestItemsDto } from './dto/create-more-test-item.dto';

@UseGuards(AuthGuard)
@Controller('test-item')
export class TestItemController {
  constructor(private readonly testItemService: TestItemService) {}

  @UseGuards(AdminGuard)

  @Post()
  create(@Body() createTestDto: CreateTestItemDto) {
    return this.testItemService.create(createTestDto);
  }

  @UseGuards(AdminGuard)

  @Post('/more')
  createMore(@Body() createMoreTestDto: CreateMoreTestItemsDto) {
    return this.testItemService.createMore(createMoreTestDto);
  }
  @Get('/all')
  findAll(@Query('test_id') test_id: string | undefined) {
    console.log('Controller - test_id received:', test_id);
    return this.testItemService.findAll(test_id);
  }

  @Get('/test/:testId')
  findByTestId(@Param('testId') testId: string) {
    return this.testItemService.findByTestId(+testId);
  }

  @UseGuards(AdminGuard)

  @Delete('/test/:testId')
  removeByTestId(@Param('testId') testId: string) {
    return this.testItemService.removeByTestId(+testId);
  }

  @UseGuards(AdminGuard)

  @Patch('/test/:testId')
  updateMany(@Param('testId') testId: string, @Body() body: { items: any[] }) {
    return this.testItemService.updateMany(+testId, body.items);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.testItemService.findOne(+id);
  }

  @UseGuards(AdminGuard)

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updateTestItemDto: UpdateTestItemDto,
  ) {
    return this.testItemService.update(+id, updateTestItemDto);
  }

  @UseGuards(AdminGuard)

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.testItemService.remove(+id);
  }
}
