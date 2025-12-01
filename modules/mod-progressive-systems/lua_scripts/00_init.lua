-- ============================================================
-- Progressive Systems - Initialization Script
-- This script ensures proper load order
-- ============================================================
-- Eluna loads scripts alphabetically, so files starting with
-- numbers load first. This ensures config loads before everything.

-- Load configuration first
if not _G.Config then
    dofile("config.lua")
end

-- Load core system
if not _G.ProgressiveCore then
    dofile("progressive_systems_core.lua")
end

-- Initialize daily challenge generator
if not _G.DailyChallengeGenerator then
    dofile("daily_challenge_generator.lua")
end

print("[Progressive Systems] Core initialization complete!")

