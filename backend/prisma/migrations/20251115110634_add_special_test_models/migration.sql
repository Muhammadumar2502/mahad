-- CreateTable
CREATE TABLE `SpecialTest` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(191) NOT NULL,
    `description` VARCHAR(191) NULL,
    `subject_id` INTEGER NOT NULL,
    `book_id` INTEGER NOT NULL,
    `section_id` INTEGER NOT NULL,
    `activation_start` DATETIME(3) NOT NULL,
    `activation_end` DATETIME(3) NOT NULL,
    `time_per_question` INTEGER NOT NULL,
    `total_time` INTEGER NOT NULL,
    `question_count` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SpecialTestQuestion` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `number` INTEGER NOT NULL,
    `question` VARCHAR(191) NOT NULL,
    `answer_A` VARCHAR(191) NOT NULL,
    `answer_B` VARCHAR(191) NOT NULL,
    `answer_C` VARCHAR(191) NULL,
    `answer_D` VARCHAR(191) NULL,
    `answer` VARCHAR(191) NOT NULL,
    `specialTestId` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SpecialTestGroup` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `specialTestId` INTEGER NOT NULL,
    `groupId` INTEGER NOT NULL,

    UNIQUE INDEX `SpecialTestGroup_specialTestId_groupId_key`(`specialTestId`, `groupId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `SpecialTestQuestion` ADD CONSTRAINT `SpecialTestQuestion_specialTestId_fkey` FOREIGN KEY (`specialTestId`) REFERENCES `SpecialTest`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SpecialTestGroup` ADD CONSTRAINT `SpecialTestGroup_specialTestId_fkey` FOREIGN KEY (`specialTestId`) REFERENCES `SpecialTest`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SpecialTestGroup` ADD CONSTRAINT `SpecialTestGroup_groupId_fkey` FOREIGN KEY (`groupId`) REFERENCES `Group`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
