-- DropForeignKey
ALTER TABLE `specialtestquestion` DROP FOREIGN KEY `SpecialTestQuestion_specialTestId_fkey`;

-- DropIndex
DROP INDEX `SpecialTestQuestion_specialTestId_fkey` ON `specialtestquestion`;

-- AddForeignKey
ALTER TABLE `SpecialTestQuestion` ADD CONSTRAINT `SpecialTestQuestion_specialTestId_fkey` FOREIGN KEY (`specialTestId`) REFERENCES `SpecialTest`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
