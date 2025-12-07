/*
 * Item Modification Coordinator
 * Ensures proper ordering and coordination of item modification systems:
 * - Item Upgrade (stat multipliers)
 * - Reforging (stat transfers)
 * - Random Enchants (enchantment additions)
 * 
 * This coordinator ensures modifications happen in the correct order
 * and don't interfere with each other.
 */

#ifndef ITEM_MODIFICATION_COORDINATOR_H
#define ITEM_MODIFICATION_COORDINATOR_H

#include "Define.h"
#include "Player.h"
#include "Item.h"

class AC_GAME_API ItemModificationCoordinator
{
public:
    static ItemModificationCoordinator* instance();

    // Initialize the coordinator
    void Initialize();
    void Shutdown();

    // Stat modification with proper ordering
    // Order: Base stat -> Reforging (flat changes) -> Item Upgrade (multipliers)
    int32 HandleStatModifier(Player* player, uint8 slot, uint32 statType, int32 baseValue);
    
    // Item modification on loot/create
    // Ensures Random Enchants and Item Upgrade don't conflict
    void HandleItemObtained(Player* player, Item* item, bool isLoot = true);

    // Check if an item should be processed by modification systems
    bool ShouldProcessItem(Player* player, Item* item);

private:
    ItemModificationCoordinator() = default;
    ~ItemModificationCoordinator() = default;
    ItemModificationCoordinator(ItemModificationCoordinator const&) = delete;
    ItemModificationCoordinator& operator=(ItemModificationCoordinator const&) = delete;
};

#define sItemModCoordinator ItemModificationCoordinator::instance()

#endif // ITEM_MODIFICATION_COORDINATOR_H

