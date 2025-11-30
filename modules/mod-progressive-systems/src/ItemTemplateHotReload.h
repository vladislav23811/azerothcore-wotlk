/*
 * Item Template Hot Reload System
 * Automatically detects new items in item_template and reloads them without server restart
 */

#ifndef ITEM_TEMPLATE_HOT_RELOAD_H
#define ITEM_TEMPLATE_HOT_RELOAD_H

#include "Define.h"
#include "World.h"
#include "DatabaseEnv.h"
#include <unordered_set>
#include <chrono>

class AC_GAME_API ItemTemplateHotReload
{
public:
    static ItemTemplateHotReload* instance();
    
    void Initialize();
    void Shutdown();
    
    // Enable/disable auto-reload
    void SetAutoReloadEnabled(bool enabled) { m_autoReloadEnabled = enabled; }
    bool IsAutoReloadEnabled() const { return m_autoReloadEnabled; }
    
    // Check for new items and reload if found
    void CheckAndReload();
    
    // Force reload all item templates
    void ForceReload();
    
    // Get last reload time
    std::chrono::system_clock::time_point GetLastReloadTime() const { return m_lastReloadTime; }
    
private:
    ItemTemplateHotReload() = default;
    ~ItemTemplateHotReload() = default;
    ItemTemplateHotReload(ItemTemplateHotReload const&) = delete;
    ItemTemplateHotReload& operator=(ItemTemplateHotReload const&) = delete;
    
    // Track known item entries
    std::unordered_set<uint32> m_knownItemEntries;
    
    // Auto-reload settings
    bool m_autoReloadEnabled = true;
    uint32 m_checkIntervalSeconds = 30; // Check every 30 seconds
    std::chrono::system_clock::time_point m_lastReloadTime;
    std::chrono::system_clock::time_point m_lastCheckTime;
    
    // Load known item entries from database
    void LoadKnownItemEntries();
    
    // Check if new items exist
    bool HasNewItems();
    
    // Perform reload
    void PerformReload();
};

#define sItemTemplateHotReload ItemTemplateHotReload::instance()

#endif // ITEM_TEMPLATE_HOT_RELOAD_H

