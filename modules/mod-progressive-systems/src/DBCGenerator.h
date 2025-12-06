/*
 * DBC Generator for Custom Items
 * Automatically generates DBC entries and MPQ patches for custom items
 */

#ifndef DBC_GENERATOR_H
#define DBC_GENERATOR_H

#include "Define.h"
#include "ItemTemplate.h"
#include <string>
#include <map>
#include <vector>

struct ItemDBCEntry
{
    uint32 ID;
    uint32 ClassID;
    uint32 SubclassID;
    int32  SoundOverrideSubclass;
    uint32 Material;
    uint32 DisplayInfoID;
    uint32 InventoryType;
    uint32 SheatheType;
};

struct ItemDisplayInfoDBCEntry
{
    uint32 ID;
    std::string ModelName[2];
    std::string ModelTexture[2];
    std::string InventoryIcon[2];
    uint32 GeosetGroup[3];
    uint32 Flags;
    uint32 SpellVisualID;
    uint32 GroupSoundIndex;
    uint32 HelmetGeosetVis[2];
    std::string Texture[8];
    uint32 ItemVisual;
    uint32 ParticleColorID;
};

class DBCGenerator
{
public:
    static DBCGenerator* instance()
    {
        static DBCGenerator instance;
        return &instance;
    }
    
    void Initialize();
    
    // Generate DBC entry for a custom item
    bool GenerateItemDBCEntry(uint32 entry, ItemTemplate const* item);
    
    // Generate ItemDisplayInfo entry (if needed)
    bool GenerateDisplayInfoDBCEntry(uint32 displayId, ItemTemplate const* item);
    
    // Check if item is custom and needs DBC generation
    bool IsCustomItem(ItemTemplate const* item);
    
    // Write all generated DBC entries to files
    bool WriteDBCFiles(const std::string& outputDir);
    
    // Generate MPQ patch from DBC files
    bool GenerateMPQPatch(const std::string& dbcDir, const std::string& outputMPQ);
    
    // Get custom DBC entries (for server-side use)
    ItemDBCEntry const* GetItemDBCEntry(uint32 entry) const;
    
    // Reload custom items (call after new items added)
    void ReloadCustomItems();
    
private:
    DBCGenerator() {}
    ~DBCGenerator() {}
    
    std::map<uint32, ItemDBCEntry> m_customItemDBC;
    std::map<uint32, ItemDisplayInfoDBCEntry> m_customDisplayInfoDBC;
    
    // Helper: Write DBC file
    bool WriteDBCFile(const std::string& filename, const std::vector<uint8>& data);
    
    // Helper: Create MPQ using external tool
    bool CreateMPQViaTool(const std::string& dbcDir, const std::string& outputMPQ);
};

#define sDBCGenerator DBCGenerator::instance()

#endif // DBC_GENERATOR_H

