/*
  Warnings:

  - You are about to drop the column `role` on the `device` table. All the data in the column will be lost.
  - You are about to drop the column `user_id` on the `device` table. All the data in the column will be lost.
  - Made the column `student_id` on table `device` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE `device` DROP FOREIGN KEY `Device_student_id_fkey`;

-- DropIndex
DROP INDEX `Device_user_id_role_is_active_idx` ON `device`;

-- AlterTable
ALTER TABLE `device` DROP COLUMN `role`,
    DROP COLUMN `user_id`,
    MODIFY `student_id` INTEGER NOT NULL;

-- CreateIndex
CREATE INDEX `Device_student_id_is_active_idx` ON `Device`(`student_id`, `is_active`);

-- AddForeignKey
ALTER TABLE `Device` ADD CONSTRAINT `Device_student_id_fkey` FOREIGN KEY (`student_id`) REFERENCES `Student`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
