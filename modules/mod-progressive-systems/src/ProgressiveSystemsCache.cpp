/*
 * Progressive Systems Cache Implementation
 */

#include "ProgressiveSystemsCache.h"
#include "Log.h"
#include <chrono>

ProgressiveSystemsCache* ProgressiveSystemsCache::instance()
{
    static ProgressiveSystemsCache instance;
    return &instance;
}

bool ProgressiveSystemsCache::GetProgressionData(uint32 guid, CachedProgressionData& data)
{
    std::lock_guard<std::mutex> lock(m_cacheMutex);
    
    auto itr = m_cache.find(guid);
    if (itr != m_cache.end())
    {
        if (IsCacheValid(itr->second))
        {
            data = itr->second;
            return true;
        }
        else
        {
            // Cache expired, remove it
            m_cache.erase(itr);
        }
    }
    
    return false;
}

void ProgressiveSystemsCache::UpdateProgressionData(uint32 guid, const CachedProgressionData& data)
{
    std::lock_guard<std::mutex> lock(m_cacheMutex);
    
    CachedProgressionData cachedData = data;
    cachedData.lastUpdate = std::chrono::system_clock::now();
    cachedData.isValid = true;
    
    m_cache[guid] = cachedData;
}

void ProgressiveSystemsCache::InvalidateCache(uint32 guid)
{
    std::lock_guard<std::mutex> lock(m_cacheMutex);
    m_cache.erase(guid);
}

void ProgressiveSystemsCache::ClearCache()
{
    std::lock_guard<std::mutex> lock(m_cacheMutex);
    m_cache.clear();
}

bool ProgressiveSystemsCache::IsCacheValid(const CachedProgressionData& data) const
{
    if (!data.isValid)
        return false;
    
    auto now = std::chrono::system_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(now - data.lastUpdate);
    
    return elapsed < CACHE_TTL;
}

