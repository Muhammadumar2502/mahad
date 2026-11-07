/*
  Warnings:

  - You are about to drop the column `image` on the `result` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `result` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE `result` DROP COLUMN `image`,
    DROP COLUMN `name`,
    ADD COLUMN `solved` INTEGER NULL;
