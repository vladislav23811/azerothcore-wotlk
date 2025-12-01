# World of Warcraft 3.3.5a Backportable Features

This document outlines features from newer WoW patches that can be backported to the 3.3.5a (WotLK) engine.

## High Priority Backports (Easy to Implement)

### 1. Transmog System
- **Source**: Patch 4.3.0 (Cataclysm)
- **Compatibility**: High - Can work with existing item system
- **Implementation**: Store appearance data, add NPC for transmog, modify item display
- **Database**: New table for transmog appearances

### 2. Account-wide Mounts
- **Source**: Patch 5.0.4 (Mists of Pandaria)
- **Compatibility**: High - Mount system exists in 3.3.5a
- **Implementation**: Share mount data across characters on same account
- **Database**: Modify character_mounts or create account_mounts table

### 3. Account-wide Pets
- **Source**: Patch 5.0.4
- **Compatibility**: High - Pet system exists
- **Implementation**: Similar to account-wide mounts
- **Database**: Account-wide pet storage

### 4. Void Storage
- **Source**: Patch 4.3.0
- **Compatibility**: Medium - Requires new storage system
- **Implementation**: Additional bank-like storage, separate from regular bank
- **Database**: New void_storage table

### 5. Guild Perks
- **Source**: Patch 4.0.1 (Cataclysm)
- **Compatibility**: High - Guild system exists
- **Implementation**: Add guild level system, unlock perks at levels
- **Features**: Mass resurrection, faster hearthstone, etc.

## Medium Priority Backports (Moderate Complexity)

### 6. Rated Battlegrounds
- **Source**: Patch 4.0.1
- **Compatibility**: Medium - BG system exists, needs rating system
- **Implementation**: Add rating to existing battlegrounds
- **Database**: Track RBG ratings separately

### 7. Looking for Raid (LFR)
- **Source**: Patch 4.3.0
- **Compatibility**: Medium - Queue system exists
- **Implementation**: Simplified raid finder, lower difficulty raids
- **Note**: Can use existing LFG system as base

### 8. Dungeon Finder Improvements
- **Source**: Multiple patches
- **Compatibility**: High - LFG exists in 3.3.5a
- **Improvements**: 
  - Role selection (Tank/Healer/DPS)
  - Better matching algorithm
  - Cross-realm support (optional)

### 9. Achievement Improvements
- **Source**: Multiple patches
- **Compatibility**: High - Achievement system exists
- **Improvements**:
  - Account-wide achievements
  - Achievement points display
  - Better UI integration

### 10. Pet Battle System (Simplified)
- **Source**: Patch 5.0.4
- **Compatibility**: Low-Medium - Requires new combat system
- **Implementation**: Simplified version without full turn-based combat
- **Note**: Can start with basic pet collection and display

## Advanced Backports (Complex)

### 11. Cross-Realm Zones
- **Source**: Patch 4.3.0
- **Compatibility**: Low - Requires significant networking changes
- **Implementation**: Share zones across realms
- **Note**: Very complex, may not be worth it

### 12. Flexible Raid Sizes
- **Source**: Patch 5.4.0 (Siege of Orgrimmar)
- **Compatibility**: Medium - Raid system exists
- **Implementation**: Allow 10-30 player raids with scaling
- **Database**: Modify raid lockouts

### 13. Personal Loot
- **Source**: Patch 6.0.2 (Warlords of Draenor)
- **Compatibility**: Medium - Loot system exists
- **Implementation**: Individual loot rolls per player
- **Note**: Can coexist with master loot

### 14. Bonus Roll System
- **Source**: Patch 5.0.4
- **Compatibility**: Medium - Loot system exists
- **Implementation**: Additional loot chance using currency
- **Currency**: Valor/Justice points or custom currency

### 15. World Quest System (Simplified)
- **Source**: Patch 7.0.3 (Legion)
- **Compatibility**: Low-Medium - Requires quest system modifications
- **Implementation**: Daily quests that refresh, simplified version
- **Note**: Can use existing daily quest system as base

## UI/UX Improvements (Easy)

### 16. Collection UI Improvements
- **Source**: Multiple patches
- **Compatibility**: High - UI can be modified
- **Features**:
  - Better mount/pet collection display
  - Search and filter options
  - Favorites system

### 17. Social Features
- **Source**: Multiple patches
- **Compatibility**: High
- **Features**:
  - Improved friend list
  - Better guild management UI
  - Cross-character communication

## Implementation Priority

### Phase 1 (Quick Wins)
1. Account-wide Mounts
2. Account-wide Pets
3. Transmog System
4. Guild Perks
5. Collection UI Improvements

### Phase 2 (Medium Effort)
6. Void Storage
7. Rated Battlegrounds
8. Dungeon Finder Improvements
9. Achievement Improvements
10. Social Features

### Phase 3 (Advanced)
11. Looking for Raid
12. Flexible Raid Sizes
13. Personal Loot
14. Bonus Roll System

### Phase 4 (Experimental)
15. Pet Battle System (Simplified)
16. World Quest System
17. Cross-Realm Zones

## Technical Considerations

### Database Changes
- Most features require new tables or modifications
- Need migration scripts for existing data
- Consider performance impact

### Client Compatibility
- Some features may require client modifications
- UI changes need compatible client patches
- Consider using existing client capabilities

### Performance
- Account-wide features increase database load
- Cross-realm features require networking overhead
- Optimize queries for new features

## Notes

- All features should maintain 3.3.5a game balance
- Consider server performance impact
- Test thoroughly before release
- Some features may need client-side patches
- Community feedback is important for prioritization

