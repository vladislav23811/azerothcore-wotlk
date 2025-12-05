-- ============================================================
-- PARAGON SYSTEM - CHARACTER DATABASE
-- Stores paragon point allocations for players
-- ============================================================

USE w_characters;

-- ============================================================
-- PARAGON ALLOCATION TABLE
-- ============================================================
-- Note: UnifiedStatSystem expects table name 'character_paragon_stats'
CREATE TABLE IF NOT EXISTS `character_paragon_stats` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Player GUID',
    `stat_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Paragon stat type (0=Core, 1=Offense, 2=Defense, 3=Utility)',
    `stat_id` INT UNSIGNED NOT NULL COMMENT 'Paragon stat ID from paragon_stat_definitions',
    `points_allocated` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points allocated to this stat',
    `last_allocated` TIMESTAMP NULL DEFAULT NULL COMMENT 'Last allocation timestamp',
    PRIMARY KEY (`guid`, `stat_id`),
    INDEX `idx_guid` (`guid`),
    INDEX `idx_stat_id` (`stat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon point allocations for players';

-- Also create character_paragon_allocation for compatibility (optional)
CREATE TABLE IF NOT EXISTS `character_paragon_allocation` (
    `guid` INT UNSIGNED NOT NULL COMMENT 'Player GUID',
    `stat_id` INT UNSIGNED NOT NULL COMMENT 'Paragon stat ID from paragon_stat_definitions',
    `points_allocated` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points allocated to this stat',
    `last_allocated` TIMESTAMP NULL DEFAULT NULL COMMENT 'Last allocation timestamp',
    PRIMARY KEY (`guid`, `stat_id`),
    INDEX `idx_guid` (`guid`),
    INDEX `idx_stat_id` (`stat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon point allocations (compatibility table)';

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT '═══════════════════════════════════════' as '';
SELECT '✅ PARAGON SYSTEM TABLES CREATED!' as '';
SELECT '═══════════════════════════════════════' as '';
