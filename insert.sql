CREATE TABLE IF NOT EXISTS `storages` (
  `stashId` varchar(50) NOT NULL PRIMARY KEY,
  `owner` varchar(48) NULL DEFAULT NULL,
  `owner_name` text NULL DEFAULT NULL,
  `creation_date` text NULL DEFAULT NULL,
  `position` json NULL DEFAULT '{}',
  `loot` json NULL DEFAULT '{}'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
