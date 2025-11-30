/*
 * Enhanced Glyph System
 * Improved glyphs with progression-based unlocks and powerful effects
 */

#ifndef ENHANCED_GLYPH_SYSTEM_H
#define ENHANCED_GLYPH_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "Spell.h"
#include <map>
#include <vector>
#include <string>

enum GlyphSlotType : uint8
{
    GLYPH_SLOT_MAJOR = 0,
    GLYPH_SLOT_MINOR = 1,
    GLYPH_SLOT_PRIME = 2,  // New: Prime glyphs (most powerful)
    GLYPH_SLOT_MAX
};

struct EnhancedGlyphData
{
    uint32 glyphId;
    uint32 spellId;
    std::string name;
    std::string description;
    GlyphSlotType slotType;
    uint32 requiredLevel;
    uint32 requiredTier;      // Progression tier required
    uint32 requiredPrestige;  // Prestige level required
    float statBonus;          // Stat bonus percentage
    float cooldownReduction;  // Cooldown reduction percentage
    float costReduction;      // Cost reduction percentage
    float damageBonus;        // Damage bonus percentage
    float healingBonus;       // Healing bonus percentage
    bool isActive;
};

class AC_GAME_API EnhancedGlyphSystem
{
public:
    static EnhancedGlyphSystem* instance();
    
    void Initialize();
    void Shutdown();
    
    // Load glyphs from database
    void LoadGlyphs();
    
    // Apply glyph effects to player
    void ApplyGlyphEffects(Player* player);
    void RemoveGlyphEffects(Player* player);
    
    // Get available glyphs for player
    std::vector<EnhancedGlyphData> GetAvailableGlyphs(Player* player, GlyphSlotType slotType);
    
    // Check if player can use glyph
    bool CanPlayerUseGlyph(Player* player, uint32 glyphId);
    
    // Apply glyph to player
    bool ApplyGlyphToPlayer(Player* player, uint32 glyphId, uint8 slot);
    bool RemoveGlyphFromPlayer(Player* player, uint8 slot);
    
    // Get glyph data
    EnhancedGlyphData* GetGlyphData(uint32 glyphId);
    
    // Progression-based glyph unlocks
    void UnlockGlyphsForTier(Player* player, uint8 tier);
    void UnlockGlyphsForPrestige(Player* player, uint32 prestigeLevel);
    
    // Custom glyph effects
    void OnSpellCast(Player* player, Spell* spell);
    void OnSpellHit(Player* player, Spell* spell, Unit* target);
    void OnPlayerKill(Player* player, Unit* victim);
    
    // Create default glyphs (fallback)
    void CreateDefaultGlyphs();
    
private:
    EnhancedGlyphSystem() = default;
    ~EnhancedGlyphSystem() = default;
    EnhancedGlyphSystem(EnhancedGlyphSystem const&) = delete;
    EnhancedGlyphSystem& operator=(EnhancedGlyphSystem const&) = delete;
    
    std::map<uint32, EnhancedGlyphData> m_glyphs; // glyphId -> data
    std::map<uint32, std::vector<uint32>> m_playerGlyphs; // playerGuid -> vector of glyphIds
    std::map<uint32, std::map<uint8, uint32>> m_playerGlyphSlots; // playerGuid -> slot -> glyphId
};

#define sEnhancedGlyphSystem EnhancedGlyphSystem::instance()

#endif // ENHANCED_GLYPH_SYSTEM_H

