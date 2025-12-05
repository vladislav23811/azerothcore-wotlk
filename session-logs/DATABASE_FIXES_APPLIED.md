# Database Fixes Applied - December 2025

## Issue Fixed: [1265] Data truncated for column 'state'

### Problem
The `updates` table in `w_characters` and `w_world` databases had an outdated ENUM definition for the `state` column. The source code uses 5 states (RELEASED, CUSTOM, PENDING, MODULE, ARCHIVED), but older databases only had 3 (RELEASED, ARCHIVED, CUSTOM).

This caused MySQL error 1265 when the DBUpdater tried to insert module updates with state='MODULE'.

### Solution Applied
Updated the `state` column ENUM in both databases to include all 5 states:

```sql
ALTER TABLE w_characters.updates 
MODIFY COLUMN state ENUM('RELEASED','ARCHIVED','CUSTOM','MODULE','PENDING') NOT NULL DEFAULT 'RELEASED';

ALTER TABLE w_world.updates 
MODIFY COLUMN state ENUM('RELEASED','ARCHIVED','CUSTOM','MODULE','PENDING') NOT NULL DEFAULT 'RELEASED';
```

### Additional Cleanup
Removed references to 14 deleted playerbots update files that were causing "missing file" warnings:
- 2025_03_03_00.sql
- 2025_05_09_00.sql
- 2025_09_16_00.sql
- 2024_08_07_00.sql
- 2025_05_05_00_accountlinking.sql
- 2025_09_18_00_ai_playerbot_french_texts.sql
- 2024_11_25_00.sql
- 2025_04_26_00.sql
- 2025_02_24_00.sql
- 2025_07_01_00_account_type.sql
- 2025_09_17_00_paladin_buff_reagent_texts.sql
- 2025_09_28_00_netherspite_beam_blocker_texts.sql
- 2025_10_09_00_ai_playerbot_texts_fix.sql
- 2025_10_27_00_ai_playerbot_german_texts.sql

### Note
The base SQL files in `data/sql/base/` already have the correct ENUM definition. This fix is only needed for databases that were created with older versions. Future fresh installations will have the correct schema automatically.

### Result
- ✅ No more [1265] errors during startup
- ✅ No more "missing file" warnings
- ✅ Module updates apply correctly
- ✅ Clean server startup

---
**Date:** December 4, 2025  
**Branch:** playerbotwithall (and master)

