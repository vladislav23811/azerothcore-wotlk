-- PvP Progression System
-- Separate progression path for PvP players

DROP TABLE IF EXISTS `character_pvp_progression`;
CREATE TABLE `character_pvp_progression` (
  `guid` INT UNSIGNED NOT NULL,
  `pvp_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'PvP progression tier',
  `pvp_rating` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP rating',
  `total_pvp_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total PvP kills',
  `total_pvp_deaths` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total PvP deaths',
  `pvp_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP progression points',
  `pvp_points_spent` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP points spent',
  `highest_rating` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest rating achieved',
  `arena_wins` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Arena wins',
  `arena_losses` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Arena losses',
  `bg_wins` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Battleground wins',
  `bg_losses` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Battleground losses',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_pvp_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PvP progression tracking';

