/*
  Warnings:

  - You are about to drop the `specialtest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `specialtestgroup` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `specialtestquestion` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE `specialtestgroup` DROP FOREIGN KEY `SpecialTestGroup_specialTestId_fkey`;

-- DropForeignKey
ALTER TABLE `specialtestquestion` DROP FOREIGN KEY `SpecialTestQuestion_specialTestId_fkey`;

-- DropTable
DROP TABLE `specialtest`;

-- DropTable
DROP TABLE `specialtestgroup`;

-- DropTable
DROP TABLE `specialtestquestion`;
