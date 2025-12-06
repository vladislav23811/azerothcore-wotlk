# Custom Items Guide - No Client Patch Required!

## 🎯 Problem
Custom items in WoW require DBC (Data Base Client) files to display icons and tooltips correctly. Without custom DBC files, players need to patch their client, which is inconvenient.

## ✅ Solution: Reuse Existing Display IDs

We solve this by **reusing existing item display IDs** from the game's default DBC files. This way, all players can see the items correctly without any patches!

### How It Works

1. **Use Existing Display IDs**: Instead of creating new display IDs, we reuse ones from existing items
2. **Item Template**: The item exists in the database with a familiar icon
3. **Addon Enhancement**: Optional addon can enhance tooltips with custom descriptions

## 📋 Implementation

### 1. Database Setup (Already Done!)

Our custom currency items use `displayid = 64062` (Emblem of Frost icon):
- ✅ Progression Token (99997)
- ✅ Celestial Token (99998)  
- ✅ Bloody Token (99999)

All players will see these items with the Emblem of Frost icon - no patch needed!

### 2. Display ID Reference

Common currency/item display IDs you can reuse:

| Display ID | Item Example | Icon Type |
|------------|--------------|-----------|
| 64062 | Emblem of Frost | Purple currency token |
| 133884 | Generic token | Coin icon |
| 133885 | Generic token | Different coin |
| 133886 | Generic token | Another coin variant |

**Recommendation**: Use 64062 (Emblem of Frost) for all currency items - it's recognizable and works for everyone!

### 3. Optional: Addon Enhancement

The addon `ProgressiveSystemsItemIcons.lua` can:
- ✅ Enhance tooltips with custom descriptions
- ✅ Add visual indicators
- ✅ Provide additional information

**Note**: The addon is optional - items work fine without it!

## 🔧 Creating New Custom Items

When creating new custom items, follow this pattern:

```sql
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, 
    `BuyPrice`, `SellPrice`, `stackable`, `InventoryType`, `ItemLevel`, 
    `RequiredLevel`, `maxcount`, `AllowableClass`, `AllowableRace`, `description`
) VALUES (
    YOUR_ITEM_ID, 10, 0, 'Your Item Name', 64062, 4, 2048,
    0, 0, 2147483647, 0, 80, 80, 0, -1, -1, 
    'Your item description.'
);
```

**Key Points**:
- `displayid = 64062` (or another existing display ID)
- `class = 10` (Miscellaneous/Currency)
- `subclass = 0` (Junk)
- `Quality = 4` (Epic/Purple)
- `Flags = 2048` (Currency Token)
- `stackable = 2147483647` (Unlimited stacking)

## 🎨 Finding Display IDs

To find display IDs of existing items:

```sql
SELECT entry, name, displayid, Quality 
FROM item_template 
WHERE class = 10 AND Quality = 4 
ORDER BY entry 
LIMIT 20;
```

Or check similar items:
```sql
SELECT entry, name, displayid 
FROM item_template 
WHERE name LIKE '%emblem%' OR name LIKE '%token%' OR name LIKE '%currency%';
```

## ⚠️ Important Notes

1. **No Custom DBC Required**: By reusing display IDs, no client patches needed!
2. **Icon Limitation**: Items will show the icon of the display ID you reuse (e.g., all will look like Emblem of Frost)
3. **Name is Unique**: The item name distinguishes it, not the icon
4. **Addon Optional**: The addon enhances but isn't required

## 🚀 Best Practices

1. **Use Consistent Display IDs**: Use the same display ID for similar item types
2. **Clear Item Names**: Make item names descriptive since icons may be similar
3. **Good Descriptions**: Add clear descriptions in the `description` field
4. **Optional Addon**: Use the addon to enhance tooltips if you want custom icons/text

## 📝 Example: Different Icons for Different Tokens

If you want different icons (still using existing ones):

```sql
-- Progression Token - Use Emblem of Frost icon
(99997, ..., 64062, ...)

-- Celestial Token - Use different existing icon (find one you like)
(99998, ..., 133884, ...)

-- Bloody Token - Use another existing icon
(99999, ..., 133885, ...)
```

**Remember**: All display IDs must exist in the default game DBC files!

## ✅ Summary

- ✅ **No client patches needed** - reuse existing display IDs
- ✅ **Works for all players** - no special setup required
- ✅ **Simple implementation** - just use existing display IDs
- ✅ **Optional enhancement** - addon can improve tooltips
- ✅ **Flexible** - can use different display IDs for variety

Your custom items will work perfectly for all players! 🎉

