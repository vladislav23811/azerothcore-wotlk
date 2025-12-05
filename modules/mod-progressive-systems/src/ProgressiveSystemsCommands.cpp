/*
 * Progressive Systems Commands
 * In-game commands for all systems
 */

#include "ProgressiveSystemsCommands.h"
#include "ProgressiveSystems.h"
#include "ItemUpgradeSystem.h"
#include "ParagonSystem.h"
#include "InfiniteDungeonSystem.h"
#include "UnifiedStatSystem.h"
#include "ProgressiveSystemsAddon.h"
#include "Chat.h"
#include "Player.h"
#include "Item.h"
#include "ItemTemplate.h"
#include <sstream>

using namespace Acore::ChatCommands;

class ProgressiveSystemsCommandScript : public CommandScript
{
public:
    ProgressiveSystemsCommandScript() : CommandScript("ProgressiveSystemsCommandScript") { }

    ChatCommandTable GetCommands() override
    {
        static ChatCommandTable progressiveSystemsCommandTable =
        {
            { "upgrade", HandleItemUpgradeCommand, SEC_PLAYER, Console::No },
            { "paragon", HandleParagonCommand, SEC_PLAYER, Console::No },
            { "dungeon", HandleDungeonCommand, SEC_PLAYER, Console::No },
            { "stats", HandleStatsCommand, SEC_PLAYER, Console::No },
            { "progression", HandleProgressionCommand, SEC_PLAYER, Console::No },
        };
        
        static ChatCommandTable commandTable =
        {
            { "ps", progressiveSystemsCommandTable },
            { "progressive", progressiveSystemsCommandTable },
        };
        
        return commandTable;
    }
    
    // .ps upgrade <itemlink> [levels]
    static bool HandleItemUpgradeCommand(ChatHandler* handler, Item* item, Optional<uint32> levels)
    {
        if (!item)
        {
            handler->PSendSysMessage("|cFFFF0000Usage: .ps upgrade <itemlink> [levels]|r");
            handler->PSendSysMessage("|cFFFFFF00Example: .ps upgrade [item:12345:0:0:0:0:0:0:0] 5|r");
            return false;
        }
        
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;
        
        uint32 upgradeLevels = levels.value_or(1);
        
        if (sItemUpgradeSystem->UpgradeItem(player, item, upgradeLevels))
        {
            handler->PSendSysMessage("|cFF00FF00Item upgraded successfully!|r");
            
            // Send update to addon
            sProgressiveSystemsAddon->SendItemUpgradeData(player);
        }
        else
        {
            handler->PSendSysMessage("|cFFFF0000Failed to upgrade item!|r");
        }
        
        return true;
    }
    
    // .ps paragon [allocate <statId> <points>|reset]
    static bool HandleParagonCommand(ChatHandler* handler, Optional<std::string> action, Optional<uint32> statId, Optional<uint32> points)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;
        
        if (!action.has_value())
        {
            // Show paragon info
            uint32 available = sParagonSystem->GetAvailableParagonPoints(player);
            uint32 total = sParagonSystem->GetTotalAllocatedPoints(player);
            uint32 level = sParagonSystem->GetParagonLevel(player);
            
            handler->PSendSysMessage("|cFF00FFFF=== Paragon System ===|r");
            handler->PSendSysMessage("|cFF00FF00Paragon Level:|r %u", level);
            handler->PSendSysMessage("|cFF00FF00Available Points:|r %u", available);
            handler->PSendSysMessage("|cFF00FF00Total Allocated:|r %u", total);
            handler->PSendSysMessage("|cFFFFFF00Use .ps paragon allocate <statId> <points> to allocate points|r");
            handler->PSendSysMessage("|cFFFFFF00Use .ps paragon reset to reset all points|r");
            
            // Send data to addon
            sProgressiveSystemsAddon->SendParagonData(player);
            
            return true;
        }
        
        if (action.value() == "allocate")
        {
            if (!statId.has_value() || !points.has_value())
            {
                handler->PSendSysMessage("|cFFFF0000Usage: .ps paragon allocate <statId> <points>|r");
                return false;
            }
            
            if (sParagonSystem->AllocateParagonPoint(player, statId.value(), points.value()))
            {
                handler->PSendSysMessage("|cFF00FF00Paragon points allocated!|r");
                sProgressiveSystemsAddon->SendParagonData(player);
            }
            else
            {
                handler->PSendSysMessage("|cFFFF0000Failed to allocate paragon points!|r");
            }
        }
        else if (action.value() == "reset")
        {
            if (sParagonSystem->ResetParagonPoints(player))
            {
                handler->PSendSysMessage("|cFF00FF00Paragon points reset!|r");
                sProgressiveSystemsAddon->SendParagonData(player);
            }
            else
            {
                handler->PSendSysMessage("|cFFFF0000Failed to reset paragon points!|r");
            }
        }
        
        return true;
    }
    
    // .ps dungeon [start|end|status]
    static bool HandleDungeonCommand(ChatHandler* handler, Optional<std::string> action)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;
        
        if (!action.has_value())
        {
            if (sInfiniteDungeonSystem->IsPlayerInDungeon(player))
            {
                auto session = sInfiniteDungeonSystem->GetDungeonSession(player);
                handler->PSendSysMessage("|cFF00FFFF=== Infinite Dungeon ===|r");
                handler->PSendSysMessage("|cFF00FF00Floor:|r %u", session.currentFloor);
                handler->PSendSysMessage("|cFF00FF00Wave:|r %u", session.currentWave);
                handler->PSendSysMessage("|cFF00FF00Kills:|r %u", session.totalKills);
            }
            else
            {
                handler->PSendSysMessage("|cFFFFFF00You are not in an Infinite Dungeon.|r");
                handler->PSendSysMessage("|cFFFFFF00Use .ps dungeon start to begin|r");
            }
            return true;
        }
        
        if (action.value() == "start")
        {
            if (sInfiniteDungeonSystem->StartDungeon(player))
            {
                handler->PSendSysMessage("|cFF00FF00Infinite Dungeon started!|r");
            }
            else
            {
                handler->PSendSysMessage("|cFFFF0000Failed to start Infinite Dungeon!|r");
            }
        }
        else if (action.value() == "end")
        {
            sInfiniteDungeonSystem->EndDungeon(player);
            handler->PSendSysMessage("|cFF00FF00Infinite Dungeon ended!|r");
        }
        
        return true;
    }
    
    // .ps stats
    static bool HandleStatsCommand(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;
        
        handler->PSendSysMessage("|cFF00FFFF=== Stat Breakdown ===|r");
        
        // Show key stats
        float strength = sUnifiedStatSystem->GetStatValue(player, StatType::STRENGTH);
        float agility = sUnifiedStatSystem->GetStatValue(player, StatType::AGILITY);
        float stamina = sUnifiedStatSystem->GetStatValue(player, StatType::STAMINA);
        float intellect = sUnifiedStatSystem->GetStatValue(player, StatType::INTELLECT);
        float spirit = sUnifiedStatSystem->GetStatValue(player, StatType::SPIRIT);
        
        handler->PSendSysMessage("|cFF00FF00Strength:|r %.0f", strength);
        handler->PSendSysMessage("|cFF00FF00Agility:|r %.0f", agility);
        handler->PSendSysMessage("|cFF00FF00Stamina:|r %.0f", stamina);
        handler->PSendSysMessage("|cFF00FF00Intellect:|r %.0f", intellect);
        handler->PSendSysMessage("|cFF00FF00Spirit:|r %.0f", spirit);
        
        handler->PSendSysMessage("|cFFFFFF00Use addon UI for detailed breakdown|r");
        
        return true;
    }
    
    // .ps progression
    static bool HandleProgressionCommand(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player)
            return false;
        
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT total_kills, current_tier, progression_points, prestige_level, total_power_level "
            "FROM character_progression_unified WHERE guid = {}", guid);
        
        if (!result)
        {
            handler->PSendSysMessage("|cFFFF0000No progression data found!|r");
            return false;
        }
        
        Field* fields = result->Fetch();
        uint32 kills = fields[0].Get<uint32>();
        uint8 tier = fields[1].Get<uint8>();
        uint64 points = fields[2].Get<uint64>();
        uint32 prestige = fields[3].Get<uint32>();
        uint32 power = fields[4].Get<uint32>();
        
        handler->PSendSysMessage("|cFF00FFFF=== Progression Status ===|r");
        handler->PSendSysMessage("|cFF00FF00Total Kills:|r %u", kills);
        handler->PSendSysMessage("|cFF00FF00Current Tier:|r %u", tier);
        handler->PSendSysMessage("|cFF00FF00Progression Points:|r %llu", points);
        handler->PSendSysMessage("|cFF00FF00Prestige Level:|r %u", prestige);
        handler->PSendSysMessage("|cFF00FF00Power Level:|r %u", power);
        
        // Send data to addon
        sProgressiveSystemsAddon->SendProgressionData(player);
        
        return true;
    }
};

void AddSC_progressive_systems_commands()
{
    new ProgressiveSystemsCommandScript();
}
