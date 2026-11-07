/*
  Warnings:

  - You are about to drop the column `section_id` on the `specialtest` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `specialtest` DROP COLUMN `section_id`,
    MODIFY `book_id` INTEGER NULL,
    MODIFY `activation_start` DATETIME(3) NULL,
    MODIFY `activation_end` DATETIME(3) NULL;

-- CreateTable
CREATE TABLE `SpecialTestSection` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `specialTestId` INTEGER NOT NULL,
    `sectionId` INTEGER NOT NULL,

    UNIQUE INDEX `SpecialTestSection_specialTestId_sectionId_key`(`specialTestId`, `sectionId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `SpecialTestSection` ADD CONSTRAINT `SpecialTestSection_specialTestId_fkey` FOREIGN KEY (`specialTestId`) REFERENCES `SpecialTest`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SpecialTestSection` ADD CONSTRAINT `SpecialTestSection_sectionId_fkey` FOREIGN KEY (`sectionId`) REFERENCES `Section`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
