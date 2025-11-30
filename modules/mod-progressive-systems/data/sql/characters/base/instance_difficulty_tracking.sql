-- Instance Difficulty Tracking
-- Stores Mythic+ difficulty tier per instance ID (not per player globally)
-- This allows different instances to have different difficulty tiers

DROP TABLE IF EXISTS `instance_difficulty_tracking`;
CREATE TABLE `instance_difficulty_tracking` (
  `instance_id` INT UNSIGNED NOT NULL COMMENT 'Instance ID from instance table',
  `map_id` SMALLINT UNSIGNED NOT NULL COMMENT 'Map ID',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Mythic+ difficulty tier (0=Normal, 1=Heroic, 2+=Mythic+)',
  `set_by_guid` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Player GUID who set this difficulty',
  `set_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When difficulty was set',
  PRIMARY KEY (`instance_id`),
  INDEX `idx_map_id` (`map_id`),
  INDEX `idx_difficulty_tier` (`difficulty_tier`),
  CONSTRAINT `fk_instance_difficulty_instance` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Mythic+ difficulty tracking per instance';

