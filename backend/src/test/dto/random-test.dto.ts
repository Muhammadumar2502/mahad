import { IsArray, IsNotEmpty, isNotEmpty, IsNumber } from 'class-validator';

export class RandomTestDto {
  @IsArray()
  @IsNotEmpty()
  sections: number[];

  @IsNumber()
  @IsNotEmpty()
  count: number;
}
