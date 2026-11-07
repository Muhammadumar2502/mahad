import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsNotEmpty,
  IsNumber,
  ValidateNested,
} from 'class-validator';
import { CreateTestItemDto } from './create-test-item.dto';

export class CreateMoreTestItemsDto {
  @IsArray()
  @ArrayMinSize(1, { message: "Kamida bitta test item bo'lishi kerak" })
  @ValidateNested({ each: true })
  @Type(() => CreateTestItemDto)
  items: CreateTestItemDto[];

  @IsNotEmpty()
  @IsNumber()
  section_id: number;
}
