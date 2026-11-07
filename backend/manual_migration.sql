-- Manual migration script for adding book fields
-- Run this script directly on your production database

-- Check if columns exist before adding them
SET @dbname = DATABASE();
SET @tablename = "Book";
SET @columnname1 = "fullBlock";
SET @columnname2 = "stepBlock";
SET @columnname3 = "passingPercentage";

-- Add fullBlock column if it doesn't exist
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME = @tablename
    AND COLUMN_NAME = @columnname1
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE `", @tablename, "` ADD COLUMN `", @columnname1, "` BOOLEAN NOT NULL DEFAULT false")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add stepBlock column if it doesn't exist
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME = @tablename
    AND COLUMN_NAME = @columnname2
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE `", @tablename, "` ADD COLUMN `", @columnname2, "` BOOLEAN NOT NULL DEFAULT false")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add passingPercentage column if it doesn't exist
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @dbname
    AND TABLE_NAME = @tablename
    AND COLUMN_NAME = @columnname3
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE `", @tablename, "` ADD COLUMN `", @columnname3, "` INT NOT NULL DEFAULT 60")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

SELECT 'Migration completed successfully' AS Status;
