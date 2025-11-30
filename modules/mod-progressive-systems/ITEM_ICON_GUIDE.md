# Item Icon Guide - Auto-Generated Items

## Problem
When creating new items dynamically, they won't have icons because icons are stored in `ItemDisplayInfo.dbc` which is a client-side DBC file that can't be modified at runtime.

## Solution
**Always use existing item entries as base templates!** This ensures icons display correctly.

## How It Works

### 1. Base Item Template
- The `AutoItemGenerator` uses existing items from `item_template` as base templates
- These items already have `DisplayInfoID` which links to `ItemDisplayInfo.dbc`
- The icon is preserved from the base item

### 2. Stat Modifications
- Stats are modified dynamically using:
  - **Enchantments** - Apply stat bonuses via enchantment slots
  - **Item Bonuses** - If the system supports it
  - **Custom Name** - Differentiate items while keeping the same base entry

### 3. Example Usage

```cpp
// GOOD: Uses existing item entry (icon will display)
ItemGenerationRule rule;
rule.baseItemEntry = 40384; // Existing item: "Betrayer of Humanity"
rule.statMultiplier = 2.0f;  // Double the stats
rule.namePrefix = "Enhanced"; // Custom name prefix

// BAD: Creating new item entry (no icon)
// Don't do this! Always use existing items.
```

## Configuration

### Database Setup
Items should reference existing entries in `item_template`:

```sql
-- Example: Use existing item as base
INSERT INTO auto_item_rules (base_item_entry, difficulty_tier, stat_multiplier, name_prefix)
VALUES (40384, 2, 1.5, 'Mythic'); -- Uses existing item 40384 as base
```

### Finding Good Base Items
1. Query `item_template` for items with the desired:
   - Item class (weapon, armor, etc.)
   - Quality level
   - Item level range
   - DisplayInfoID (must be > 0)

```sql
-- Find items with icons in a specific category
SELECT entry, name, DisplayInfoID, Quality, ItemLevel 
FROM item_template 
WHERE Class = 2 -- Weapons
  AND Quality >= 3 -- Rare or better
  AND DisplayInfoID > 0 -- Has icon
ORDER BY ItemLevel DESC;
```

## Best Practices

1. **Always use existing item entries** - Never create completely new items
2. **Choose appropriate base items** - Match the item type and quality you want
3. **Use custom names** - Differentiate items with prefixes/suffixes
4. **Apply stats via enchantments** - Preserves base item icon
5. **Test icon display** - Verify icons show correctly in-game

## Technical Details

### Item Structure
- `ItemTemplate::DisplayInfoID` - Links to `ItemDisplayInfo.dbc`
- `ItemDisplayInfoEntry::inventoryIcon` - The actual icon path (e.g., "INV_Sword_25")
- Client reads icons from DBC files, not from server

### Why This Works
- Server sends item entry ID to client
- Client looks up `DisplayInfoID` from `Item.dbc`
- Client looks up icon from `ItemDisplayInfo.dbc` using `DisplayInfoID`
- Since we use existing entries, the client finds the icon automatically

## Troubleshooting

### Item shows no icon
1. Check if base item has `DisplayInfoID > 0`
2. Verify the item exists in `item_template`
3. Ensure client has the DBC files loaded

### Icon doesn't match item
- This is expected if you're using a different base item
- Consider using a base item that matches the desired appearance
- Or accept that the icon represents the item type, not exact appearance

## Future Enhancements

If you need custom icons:
1. **Client Addon** - Could potentially override icons client-side (limited)
2. **DBC Modification** - Requires distributing custom DBC files to all clients
3. **Item Visual System** - Use existing item visuals that match desired appearance

For now, using existing items is the most reliable solution that works without client modifications.

