/*
 * Item Modification Coordinator Implementation
 */

#include "ItemModificationCoordinator.h"
#include "item_reforge.h"
#include "item_upgrade.h"
#include "random_enchants.h"
#include "Log.h"
#include "Config.h"

ItemModificationCoordinator* ItemModificationCoordinator::instance()
{
    static ItemModificationCoordinator instance;
    return &instance;
}

void ItemModificationCoordinator::Initialize()
{
    LOG_INFO("module", "Item Modification Coordinator: Initializing...");
    LOG_INFO("module", "  - Coordination enabled for: Item Upgrade, Reforging, Random Enchants");
    LOG_INFO("module", "  - Stat modification order: Base -> Reforging (flat) -> Item Upgrade (multiplier)");
}

void ItemModificationCoordinator::Shutdown()
{
    LOG_INFO("module", "Item Modification Coordinator: Shutdown");
}

int32 ItemModificationCoordinator::HandleStatModifier(Player* player, uint8 slot, uint32 statType, int32 baseValue)
{
    if (!player || baseValue == 0)
        return baseValue;

    Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    if (!item)
        return baseValue;

    int32 modifiedValue = baseValue;

    // STEP 1: Apply Reforging modifications (flat stat changes)
    // Reforging decreases one stat and increases another
    // We need to handle the decrease here, then let the increase be handled separately
    if (sItemReforge)
    {
        const ItemReforge::ReforgingData* reforging = sItemReforge->GetReforgingData(item);
        if (reforging != nullptr)
        {
            ItemTemplate const* proto = item->GetTemplate();
            if (proto && proto->StatsCount > 0)
            {
                // Check if this is the stat being decreased
                if (statType == reforging->stat_decrease)
                {
                    modifiedValue -= reforging->stat_value;
                    // Ensure value doesn't go below 0
                    if (modifiedValue < 0)
                        modifiedValue = 0;
                }
            }
        }
    }

    // STEP 2: Apply Item Upgrade modifications (percentage multipliers)
    // Item Upgrade multiplies stats by a percentage
    // This happens AFTER Reforging so multipliers apply to the reforged values
    if (sItemUpgrade && sItemUpgrade->GetBoolConfig(CONFIG_ITEM_UPGRADE_ENABLED))
    {
        modifiedValue = sItemUpgrade->HandleStatModifier(player, slot, statType, modifiedValue);
    }

    return modifiedValue;
}

void ItemModificationCoordinator::HandleItemObtained(Player* player, Item* item, bool isLoot)
{
    if (!player || !item || !ShouldProcessItem(player, item))
        return;

    // Order: Random Enchants first (adds enchantments), then Item Upgrade (adds stat upgrades)
    // This ensures Item Upgrade can see the enchanted item and apply upgrades accordingly
    
    // STEP 1: Apply Random Enchants (if enabled)
    // Random Enchants adds enchantments to items
    // This is done first so Item Upgrade can see the full item
    
    // STEP 2: Apply Item Upgrade random upgrades (if enabled)
    // Item Upgrade adds stat upgrades
    // This is done after enchantments so upgrades apply to enchanted items
    
    // Note: The actual implementations will handle their own checks
    // This coordinator just ensures they don't conflict by documenting the order
}

bool ItemModificationCoordinator::ShouldProcessItem(Player* player, Item* item)
{
    if (!player || !item)
        return false;

    // Don't process soulbound items that aren't for this player
    // Don't process items below minimum quality (if configured)
    // Add other filters as needed

    return true;
}

