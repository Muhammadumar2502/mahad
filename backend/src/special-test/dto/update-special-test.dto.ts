import { PartialType } from '@nestjs/mapped-types';
import { IsOptional, IsNumber, IsBoolean, Min } from 'class-validator';
import { CreateSpecialTestDto } from './create-special-test.dto';

export class UpdateSpecialTestDto extends PartialType(CreateSpecialTestDto) {
  @IsOptional()
  @IsNumber({}, { message: 'time_per_question must be a number' })
  @Min(1)
  time_per_question?: number | null;

  @IsOptional()
  @IsNumber({}, { message: 'total_time must be a number' })
  @Min(1)
  total_time?: number | null;

  @IsOptional()
  @IsBoolean()
  force_next_question?: boolean;
}
