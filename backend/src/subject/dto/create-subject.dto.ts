import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
// import { HasMimeType, IsFile, MaxFileSize, MemoryStoredFile } from 'nestjs-form-data';

export class CreateSubjectDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  imgPath?: string;

  //     @IsFile()
  //   @MaxFileSize(1e6)
  //   @HasMimeType(['image/jpeg', 'image/png'])
  //   image: MemoryStoredFile;
}
