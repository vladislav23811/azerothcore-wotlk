/*
 * DBC Generator Implementation
 */

#include "DBCGenerator.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "WorldDatabase.h"
#include "ObjectMgr.h"
#include <fstream>
#include <sstream>
#include <filesystem>

void DBCGenerator::Initialize()
{
    LOG_INFO("module", "DBCGenerator: Initializing...");
    
    // Don't reload here - wait for items to be loaded first
    // This will be called after ObjectMgr::LoadItemTemplates()
    LOG_INFO("module", "DBCGenerator: Ready. Call ReloadCustomItems() after items are loaded.");
}

bool DBCGenerator::IsCustomItem(ItemTemplate const* item)
{
    if (!item)
        return false;
    
    // Method 1: Entry range (custom items start at 99990)
    if (item->ItemId >= 99990)
        return true;
    
    // Method 2: Check custom_weapon_templates table
    QueryResult result = WorldDatabase.Query(
        "SELECT 1 FROM custom_weapon_templates WHERE custom_entry = {}", 
        item->ItemId);
    if (result)
        return true;
    
    // Method 3: Check if is_custom flag exists (future enhancement)
    // QueryResult result2 = WorldDatabase.Query(
    //     "SELECT is_custom FROM item_template WHERE entry = {}", item->ItemId);
    // if (result2 && result2->Fetch()[0].Get<bool>())
    //     return true;
    
    return false;
}

bool DBCGenerator::GenerateItemDBCEntry(uint32 entry, ItemTemplate const* item)
{
    if (!item)
    {
        // Try to get from ObjectMgr if item is null
        item = sObjectMgr->GetItemTemplate(entry);
        if (!item)
            return false;
    }
    
    ItemDBCEntry dbcEntry;
    dbcEntry.ID = entry;
    dbcEntry.ClassID = item->Class;
    dbcEntry.SubclassID = item->SubClass;
    dbcEntry.SoundOverrideSubclass = item->SoundOverrideSubclass;
    dbcEntry.Material = item->Material;
    dbcEntry.DisplayInfoID = item->DisplayInfoID;
    dbcEntry.InventoryType = item->InventoryType;
    dbcEntry.SheatheType = item->Sheath;
    
    m_customItemDBC[entry] = dbcEntry;
    
    LOG_DEBUG("module", "DBCGenerator: Generated Item.dbc entry for item {}", entry);
    return true;
}

bool DBCGenerator::GenerateDisplayInfoDBCEntry(uint32 displayId, ItemTemplate const* item)
{
    // For now, we reuse existing display IDs
    // In the future, we could generate new display info entries
    // This would require model files, which is complex
    
    LOG_DEBUG("module", "DBCGenerator: Using existing display ID {} for item {}", 
              displayId, item ? item->ItemId : 0);
    return true;
}

bool DBCGenerator::WriteDBCFiles(const std::string& outputDir)
{
    if (m_customItemDBC.empty())
    {
        LOG_INFO("module", "DBCGenerator: No custom items to write");
        return true; // Not an error, just nothing to do
    }
    
    // Create output directory if it doesn't exist
    try
    {
        std::filesystem::create_directories(outputDir);
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "DBCGenerator: Failed to create directory {}: {}", outputDir, e.what());
        return false;
    }
    
    // Write Item.dbc in CSV format (easier to convert to binary DBC later)
    std::string itemDBCPath = outputDir + "/Item.dbc.csv";
    std::ofstream itemFile(itemDBCPath);
    
    if (!itemFile.is_open())
    {
        LOG_ERROR("module", "DBCGenerator: Failed to open {} for writing", itemDBCPath);
        return false;
    }
    
    // Write CSV header
    itemFile << "ID,ClassID,SubclassID,SoundOverrideSubclass,Material,DisplayInfoID,InventoryType,SheatheType\n";
    
    // Write entries
    for (const auto& pair : m_customItemDBC)
    {
        const ItemDBCEntry& entry = pair.second;
        
        itemFile << entry.ID << ","
                 << entry.ClassID << ","
                 << entry.SubclassID << ","
                 << entry.SoundOverrideSubclass << ","
                 << entry.Material << ","
                 << entry.DisplayInfoID << ","
                 << entry.InventoryType << ","
                 << entry.SheatheType << "\n";
    }
    
    itemFile.close();
    
    LOG_INFO("module", "DBCGenerator: Wrote {} custom item entries to {}", 
             m_customItemDBC.size(), itemDBCPath);
    
    return true;
}

bool DBCGenerator::GenerateMPQPatch(const std::string& dbcDir, const std::string& outputMPQ)
{
    // First, write DBC files
    if (!WriteDBCFiles(dbcDir))
    {
        LOG_ERROR("module", "DBCGenerator: Failed to write DBC files");
        return false;
    }
    
    // Create MPQ using external tool (Python script)
    // This is simpler than implementing MPQ creation in C++
    std::string scriptPath = "tools/generate_patch.py";
    std::string command = "python " + scriptPath + " " + dbcDir + " " + outputMPQ;
    
    LOG_INFO("module", "DBCGenerator: Generating MPQ patch via: {}", command);
    
    int result = system(command.c_str());
    
    if (result != 0)
    {
        LOG_ERROR("module", "DBCGenerator: Failed to generate MPQ patch");
        return false;
    }
    
    LOG_INFO("module", "DBCGenerator: Successfully generated MPQ patch: {}", outputMPQ);
    return true;
}

ItemDBCEntry const* DBCGenerator::GetItemDBCEntry(uint32 entry) const
{
    auto it = m_customItemDBC.find(entry);
    if (it != m_customItemDBC.end())
        return &it->second;
    return nullptr;
}

void DBCGenerator::ReloadCustomItems()
{
    m_customItemDBC.clear();
    
    // Get ObjectMgr to access item templates
    // We'll process items that are already loaded
    // This is called after ObjectMgr::LoadItemTemplates()
    
    // Query all custom items from database
    QueryResult result = WorldDatabase.Query(
        "SELECT entry FROM item_template WHERE entry >= 99990 "
        "UNION "
        "SELECT custom_entry FROM custom_weapon_templates WHERE custom_entry IS NOT NULL");
    
    if (!result)
    {
        LOG_INFO("module", "DBCGenerator: No custom items found");
        return;
    }
    
    uint32 count = 0;
    do
    {
        uint32 entry = result->Fetch()[0].Get<uint32>();
        
        // Get item template from ObjectMgr (already loaded)
        // We need to include ObjectMgr.h for this
        // For now, we'll generate DBC entry directly from database
        
        QueryResult itemResult = WorldDatabase.Query(
            "SELECT entry, class, subclass, SoundOverrideSubclass, Material, displayid, "
            "InventoryType, sheath FROM item_template WHERE entry = {}", entry);
        
        if (itemResult)
        {
            Field* fields = itemResult->Fetch();
            ItemDBCEntry dbcEntry;
            dbcEntry.ID = fields[0].Get<uint32>();
            dbcEntry.ClassID = fields[1].Get<uint32>();
            dbcEntry.SubclassID = fields[2].Get<uint32>();
            dbcEntry.SoundOverrideSubclass = fields[3].Get<int32>();
            dbcEntry.Material = fields[4].Get<uint32>();
            dbcEntry.DisplayInfoID = fields[5].Get<uint32>();
            dbcEntry.InventoryType = fields[6].Get<uint32>();
            dbcEntry.SheatheType = fields[7].Get<uint32>();
            
            m_customItemDBC[entry] = dbcEntry;
            count++;
            
            LOG_DEBUG("module", "DBCGenerator: Generated DBC entry for item {}", entry);
        }
        
    } while (result->NextRow());
    
    LOG_INFO("module", "DBCGenerator: Processed {} custom items", count);
}

bool DBCGenerator::CreateMPQViaTool(const std::string& dbcDir, const std::string& outputMPQ)
{
    return GenerateMPQPatch(dbcDir, outputMPQ);
}

