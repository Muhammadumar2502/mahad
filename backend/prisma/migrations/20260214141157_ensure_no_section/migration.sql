/*
  Warnings:

  - You are about to drop the column `section_id` on the `test` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE `test` DROP FOREIGN KEY `Test_section_id_fkey`;

-- DropIndex
DROP INDEX `Test_section_id_key` ON `test`;

-- AlterTable
ALTER TABLE `test` DROP COLUMN `section_id`;
