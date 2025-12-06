/*
 * DBC Generator Implementation
 */

#include "DBCGenerator.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "WorldDatabase.h"
#include "ObjectMgr.h"
#include "Config.h"
#include "QueryResult.h"
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
    
    // Method 1: Entry range (configurable, default: 999000)
    // This avoids conflicts with any existing items
    uint32 customItemThreshold = sConfigMgr->GetOption<uint32>("ProgressiveSystems.DBC.CustomItemThreshold", 999000);
    if (item->ItemId >= customItemThreshold)
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
    // Check if auto-generation is enabled
    bool autoGenerate = sConfigMgr->GetOption<bool>("ProgressiveSystems.DBC.AutoGenerateMPQ", true);
    if (!autoGenerate)
    {
        LOG_INFO("module", "DBCGenerator: MPQ auto-generation disabled in config");
        return false;
    }
    
    // First, write DBC files
    if (!WriteDBCFiles(dbcDir))
    {
        LOG_ERROR("module", "DBCGenerator: Failed to write DBC files");
        return false;
    }
    
    // Create MPQ using C++ tool (preferred) or Python script (fallback)
    // Get absolute paths
    std::filesystem::path dbcPath(dbcDir);
    std::filesystem::path mpqPath(outputMPQ);
    
    if (!dbcPath.is_absolute())
        dbcPath = std::filesystem::current_path() / dbcPath;
    if (!mpqPath.is_absolute())
        mpqPath = std::filesystem::current_path() / mpqPath;
    
    // Create output directory if needed
    std::filesystem::create_directories(mpqPath.parent_path());
    
    // Try C++ tool first (mpq_creator)
    #ifdef _WIN32
    // On Windows, try to find the tool in common locations
    // Server typically runs from release/ directory, tool is in build/bin/
    std::vector<std::filesystem::path> toolPaths = {
        std::filesystem::current_path() / "mpq_creator.exe",  // Release directory
        std::filesystem::current_path() / "bin/RelWithDebInfo/mpq_creator.exe",
        std::filesystem::current_path() / "bin/Debug/mpq_creator.exe",
        std::filesystem::current_path() / "bin/Release/mpq_creator.exe",
        std::filesystem::current_path().parent_path() / "build/bin/RelWithDebInfo/mpq_creator.exe",  // From release/ to build/bin/
        std::filesystem::current_path().parent_path() / "build/bin/Debug/mpq_creator.exe",
        std::filesystem::current_path().parent_path() / "build/bin/Release/mpq_creator.exe",
        // Also try absolute path based on common structure
        std::filesystem::path("C:/servery/WOTLK-BOTS/build/bin/RelWithDebInfo/mpq_creator.exe")
    };
    
    std::string toolCmd;
    for (const auto& path : toolPaths)
    {
        if (std::filesystem::exists(path))
        {
            toolCmd = "\"" + path.string() + "\"";
            break;
        }
    }
    
    if (!toolCmd.empty())
    {
        std::string command = toolCmd + " \"" + dbcPath.string() + "\" \"" + mpqPath.string() + "\"";
        LOG_INFO("module", "DBCGenerator: Generating MPQ patch via C++ tool: {}", command);
        
        int result = system(command.c_str());
        
        if (result == 0)
        {
            LOG_INFO("module", "DBCGenerator: Successfully generated MPQ patch: {}", outputMPQ);
            return true;
        }
        else
        {
            LOG_WARN("module", "DBCGenerator: C++ tool failed, trying Python fallback...");
        }
    }
    #endif
    
    // Fallback to Python script
    std::string scriptPath = "tools/generate_patch.py";
    std::string pythonCmd = "\"C:\\Program Files\\PyManager\\python.exe\"";
    
    // Test if Python exists at that path, otherwise fall back to "python"
    #ifdef _WIN32
    std::string testCmd = pythonCmd + " --version >nul 2>&1";
    if (system(testCmd.c_str()) != 0)
    {
        pythonCmd = "python";  // Fall back to PATH
    }
    #endif
    
    std::string command = pythonCmd + " \"" + scriptPath + "\" \"" + dbcPath.string() + "\" \"" + mpqPath.string() + "\"";
    
    LOG_INFO("module", "DBCGenerator: Generating MPQ patch via Python: {}", command);
    
    int result = system(command.c_str());
    
    if (result != 0)
    {
        LOG_WARN("module", "DBCGenerator: Failed to generate MPQ patch");
        LOG_WARN("module", "DBCGenerator: Please ensure mpq_creator tool is built or pympq is installed");
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
    
    // Get configurable threshold
    uint32 customItemThreshold = sConfigMgr->GetOption<uint32>("ProgressiveSystems.DBC.CustomItemThreshold", 999000);
    
    // Query all custom items from database
    QueryResult result = WorldDatabase.Query(
        "SELECT entry FROM item_template WHERE entry >= {} "
        "UNION "
        "SELECT custom_entry FROM custom_weapon_templates WHERE custom_entry IS NOT NULL",
        customItemThreshold);
    
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

