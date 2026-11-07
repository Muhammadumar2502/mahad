-- AlterTable
ALTER TABLE `result` ADD COLUMN `finishTime` DATETIME(3) NULL,
    ADD COLUMN `special_test_id` INTEGER NULL,
    ADD COLUMN `startTime` DATETIME(3) NULL;

-- AlterTable
ALTER TABLE `specialtest` MODIFY `time_per_question` INTEGER NULL,
    MODIFY `total_time` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `Result` ADD CONSTRAINT `Result_special_test_id_fkey` FOREIGN KEY (`special_test_id`) REFERENCES `SpecialTest`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
