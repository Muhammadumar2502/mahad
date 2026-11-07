/*
  Warnings:

  - You are about to drop the column `book_id` on the `specialtest` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `group` ADD COLUMN `forceNextQuestion` BOOLEAN NULL DEFAULT false;

-- AlterTable
ALTER TABLE `specialtest` DROP COLUMN `book_id`,
    ADD COLUMN `force_next_question` BOOLEAN NULL DEFAULT false;

-- CreateTable
CREATE TABLE `SpecialTestBook` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `specialTestId` INTEGER NOT NULL,
    `bookId` INTEGER NOT NULL,

    UNIQUE INDEX `SpecialTestBook_specialTestId_bookId_key`(`specialTestId`, `bookId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `SpecialTestBook` ADD CONSTRAINT `SpecialTestBook_specialTestId_fkey` FOREIGN KEY (`specialTestId`) REFERENCES `SpecialTest`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SpecialTestBook` ADD CONSTRAINT `SpecialTestBook_bookId_fkey` FOREIGN KEY (`bookId`) REFERENCES `Book`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
