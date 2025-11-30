/*
 * Progressive Systems Cache
 * Performance optimization with caching layer
 */

#ifndef PROGRESSIVE_SYSTEMS_CACHE_H
#define PROGRESSIVE_SYSTEMS_CACHE_H

#include "Define.h"
#include "Player.h"
#include <unordered_map>
#include <mutex>
#include <chrono>

struct CachedProgressionData
{
    uint32 totalKills = 0;
    uint8 currentTier = 1;
    uint8 difficultyTier = 1;
    uint64 progressionPoints = 0;
    uint32 prestigeLevel = 0;
    uint32 powerLevel = 0;
    std::chrono::system_clock::time_point lastUpdate;
    bool isValid = false;
};

class AC_GAME_API ProgressiveSystemsCache
{
public:
    static ProgressiveSystemsCache* instance();
    
    // Get cached progression data
    bool GetProgressionData(uint32 guid, CachedProgressionData& data);
    
    // Update cached progression data
    void UpdateProgressionData(uint32 guid, const CachedProgressionData& data);
    
    // Invalidate cache for player
    void InvalidateCache(uint32 guid);
    
    // Clear all cache
    void ClearCache();
    
    // Check if cache is valid (not expired)
    bool IsCacheValid(const CachedProgressionData& data) const;
    
private:
    ProgressiveSystemsCache() = default;
    ~ProgressiveSystemsCache() = default;
    ProgressiveSystemsCache(ProgressiveSystemsCache const&) = delete;
    ProgressiveSystemsCache& operator=(ProgressiveSystemsCache const&) = delete;
    
    std::unordered_map<uint32, CachedProgressionData> m_cache;
    std::mutex m_cacheMutex;
    static constexpr std::chrono::seconds CACHE_TTL{30}; // 30 second cache
};

#define sProgressiveSystemsCache ProgressiveSystemsCache::instance()

#endif // PROGRESSIVE_SYSTEMS_CACHE_H

