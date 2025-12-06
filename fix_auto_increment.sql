USE w_world;

-- Fix AUTO_INCREMENT for bloody_palace_bosses table
SET @max_id = (SELECT COALESCE(MAX(boss_id), 0) FROM bloody_palace_bosses);
SET @sql = CONCAT('ALTER TABLE bloody_palace_bosses AUTO_INCREMENT = ', @max_id + 1);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT CONCAT('AUTO_INCREMENT fixed. Next value will be: ', @max_id + 1) AS result;

