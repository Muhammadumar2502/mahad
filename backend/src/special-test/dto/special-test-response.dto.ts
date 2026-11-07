import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsNumber,
  IsArray,
  IsDateString,
  IsBoolean,
  Min,
  ArrayMinSize,
} from 'class-validator';

export class SpecialTestResponseDto {
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @IsNotEmpty()
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNotEmpty()
  @IsNumber()
  subject_id: number;

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  book_ids?: number[];

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  section_ids?: number[];

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  group_ids?: number[];

  @IsOptional()
  @IsDateString()
  activation_start?: string;

  @IsOptional()
  @IsDateString()
  activation_end?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  time_per_question?: number;

  @IsOptional()
  @IsNumber()
  @Min(1)
  total_time?: number;

  @IsOptional()
  @IsBoolean()
  force_next_question?: boolean;

  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  question_count: number;

  @IsNotEmpty()
  @IsArray()
  @ArrayMinSize(1)
  questions: SpecialTestQuestionResponseDto[];

  @IsOptional()
  @IsString()
  createdAt?: string;

  @IsOptional()
  @IsString()
  updatedAt?: string;
}

export class SpecialTestQuestionResponseDto {
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  number: number;

  @IsNotEmpty()
  @IsString()
  question: string;

  @IsNotEmpty()
  @IsString()
  answer_A: string;

  @IsNotEmpty()
  @IsString()
  answer_B: string;

  @IsOptional()
  @IsString()
  answer_C?: string;

  @IsOptional()
  @IsString()
  answer_D?: string;

  @IsNotEmpty()
  @IsString()
  answer: string;
}
