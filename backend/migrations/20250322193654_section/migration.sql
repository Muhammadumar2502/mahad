/*
  Warnings:

  - A unique constraint covering the columns `[section_id]` on the table `Test` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX `Test_section_id_key` ON `Test`(`section_id`);
