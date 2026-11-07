-- AlterTable
ALTER TABLE `result` ADD COLUMN `student_id` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `Result` ADD CONSTRAINT `Result_student_id_fkey` FOREIGN KEY (`student_id`) REFERENCES `Student`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
