import { Module } from '@nestjs/common';
import { BookService } from './book.service';
import { BookController } from './book.controller';
import { MulterModule } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { join } from 'path';

@Module({
  imports: [
    MulterModule.register({
      storage: diskStorage({
        destination: join(__dirname, '..', '..', 'public', 'books'),
        filename: (req, file, cb) => {
          const filename = `${Date.now()}-${file.originalname}`;
          req.body.imgPath = `/static/books/${filename}`;
          cb(null, filename);
        },
      }),
    }),
  ],
  controllers: [BookController],
  providers: [BookService],
})
export class BookModule {}
