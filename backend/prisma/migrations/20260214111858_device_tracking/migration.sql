-- CreateTable
CREATE TABLE `Device` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER NOT NULL,
    `role` ENUM('ADMIN', 'STUDENT', 'TEACHER') NOT NULL,
    `device_name` VARCHAR(191) NOT NULL,
    `device_type` ENUM('ANDROID', 'IOS', 'WEB') NOT NULL,
    `device_identifier` VARCHAR(191) NOT NULL,
    `ip_address` VARCHAR(191) NULL,
    `user_agent` TEXT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `last_active` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `last_api_endpoint` VARCHAR(191) NULL,
    `last_api_method` VARCHAR(191) NULL,
    `app_version` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Device_user_id_role_is_active_idx`(`user_id`, `role`, `is_active`),
    INDEX `Device_device_identifier_idx`(`device_identifier`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
