/*
  Warnings:

  - A unique constraint covering the columns `[student_id]` on the table `Device` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE `device` ADD COLUMN `student_id` INTEGER NULL;

-- CreateIndex
CREATE UNIQUE INDEX `Device_student_id_key` ON `Device`(`student_id`);

-- AddForeignKey
ALTER TABLE `Device` ADD CONSTRAINT `Device_student_id_fkey` FOREIGN KEY (`student_id`) REFERENCES `Student`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
