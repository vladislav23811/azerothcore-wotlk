/*
 * Item Template Hot Reload System Implementation
 * Automatically detects new items in item_template and reloads them without server restart
 */

#include "ItemTemplateHotReload.h"
#include "ObjectMgr.h"
#include "Log.h"
#include "World.h"
#include "DatabaseEnv.h"
#include <chrono>

ItemTemplateHotReload* ItemTemplateHotReload::instance()
{
    static ItemTemplateHotReload instance;
    return &instance;
}

void ItemTemplateHotReload::Initialize()
{
    LOG_INFO("module", "Item Template Hot Reload: Initializing...");
    
    // Load known item entries
    LoadKnownItemEntries();
    
    m_lastReloadTime = std::chrono::system_clock::now();
    m_lastCheckTime = std::chrono::system_clock::now();
    
    // Schedule periodic checks
    // Note: TaskScheduler not available at World level, using manual checks on item load instead
    // Periodic checks can be implemented via WorldScript hooks or manual polling
    if (m_autoReloadEnabled)
    {
        LOG_INFO("module", "Item Template Hot Reload: Auto-reload enabled (manual check on item access)");
    }
    
    LOG_INFO("module", "Item Template Hot Reload: Initialized (Auto-reload: {})", m_autoReloadEnabled ? "Enabled" : "Disabled");
}

void ItemTemplateHotReload::Shutdown()
{
    m_knownItemEntries.clear();
    LOG_INFO("module", "Item Template Hot Reload: Shutdown");
}

void ItemTemplateHotReload::LoadKnownItemEntries()
{
    m_knownItemEntries.clear();
    
    QueryResult result = WorldDatabase.Query("SELECT entry FROM item_template");
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 entry = fields[0].Get<uint32>();
            m_knownItemEntries.insert(entry);
        } while (result->NextRow());
        
        LOG_INFO("module", "Item Template Hot Reload: Loaded {} known item entries", m_knownItemEntries.size());
    }
}

bool ItemTemplateHotReload::HasNewItems()
{
    QueryResult result = WorldDatabase.Query("SELECT entry FROM item_template");
    if (!result)
        return false;
    
    std::unordered_set<uint32> currentEntries;
    do
    {
        Field* fields = result->Fetch();
        uint32 entry = fields[0].Get<uint32>();
        currentEntries.insert(entry);
        
        // Check if this is a new entry
        if (m_knownItemEntries.find(entry) == m_knownItemEntries.end())
        {
            LOG_INFO("module", "Item Template Hot Reload: Detected new item entry: {}", entry);
            return true;
        }
    } while (result->NextRow());
    
    // Also check for deleted items (entries in known but not in current)
    for (uint32 entry : m_knownItemEntries)
    {
        if (currentEntries.find(entry) == currentEntries.end())
        {
            LOG_INFO("module", "Item Template Hot Reload: Detected deleted item entry: {}", entry);
            return true;
        }
    }
    
    return false;
}

void ItemTemplateHotReload::PerformReload()
{
    LOG_INFO("module", "Item Template Hot Reload: Reloading item templates...");
    
    // Clear existing item templates
    sObjectMgr->ClearItemTemplates();
    
    // Reload all item templates from database
    sObjectMgr->LoadItemTemplates();
    
    // Reload item locales
    sObjectMgr->LoadItemLocales();
    
    // Update known entries
    LoadKnownItemEntries();
    
    m_lastReloadTime = std::chrono::system_clock::now();
    
    LOG_INFO("module", "Item Template Hot Reload: Item templates reloaded successfully!");
}

void ItemTemplateHotReload::CheckAndReload()
{
    if (!m_autoReloadEnabled)
        return;
    
    auto now = std::chrono::system_clock::now();
    auto timeSinceLastCheck = std::chrono::duration_cast<std::chrono::seconds>(now - m_lastCheckTime).count();
    
    // Only check if enough time has passed
    if (timeSinceLastCheck < m_checkIntervalSeconds)
        return;
    
    m_lastCheckTime = now;
    
    // Check for new items
    if (HasNewItems())
    {
        LOG_INFO("module", "Item Template Hot Reload: New items detected! Reloading...");
        PerformReload();
    }
}

void ItemTemplateHotReload::ForceReload()
{
    LOG_INFO("module", "Item Template Hot Reload: Force reload requested");
    PerformReload();
}

