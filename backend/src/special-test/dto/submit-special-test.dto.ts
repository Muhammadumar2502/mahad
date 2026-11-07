import { IsNotEmpty, IsObject } from 'class-validator';

export class SubmitSpecialTestDto {
  @IsNotEmpty()
  @IsObject()
  answers: Record<string, string>; // key: question_id, value: answer (A,B,C,D)
}
