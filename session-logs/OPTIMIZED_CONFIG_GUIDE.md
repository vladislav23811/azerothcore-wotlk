# 🎯 Optimized Configuration Guide
## Pre-configured for Progressive Server Vision

---

## ✅ **WORLDSERVER.CONF OPTIMIZATIONS**

### **Experience Rates** (Progressive Vision)
```ini
# Base rates - balanced for long-term progression
Rate.XP.Kill      = 2.0   # 2x XP from kills (respects player time)
Rate.XP.Quest     = 1.5   # 1.5x XP from quests
Rate.XP.Explore   = 1.0   # Normal exploration XP
Rate.XP.Pet       = 2.0   # 2x XP for pets
Rate.XP.Group     = 1.2   # 20% bonus for grouping (encourages groups)

# Battleground XP
Rate.XP.BattlegroundKillAV   = 2.5
Rate.XP.BattlegroundKillWSG  = 2.5
Rate.XP.BattlegroundKillAB   = 2.5
Rate.XP.BattlegroundKillEOTS = 2.5
Rate.XP.BattlegroundKillSOTA = 2.5
Rate.XP.BattlegroundKillIC   = 2.5
Battleground.GiveXPForKills = 1
```

### **Loot Rates** (Better loot for higher difficulty)
```ini
Rate.Drop.Item.Poor       = 1.0
Rate.Drop.Item.Normal     = 1.0
Rate.Drop.Item.Uncommon   = 1.2   # 20% more uncommon
Rate.Drop.Item.Rare        = 1.5   # 50% more rare
Rate.Drop.Item.Epic        = 1.2   # 20% more epic
Rate.Drop.Item.Legendary   = 1.0   # Normal (rare)
Rate.Drop.Money            = 1.5   # 1.5x money
```

### **Reputation & Honor** (Encourage PvP)
```ini
Rate.Reputation.Gain = 2.0
Rate.Honor = 2.0
Rate.ArenaPoints = 1.5
MaxHonorPoints = 100000
MaxArenaPoints = 15000
HonorPointsAfterDuel = 10
```

### **Skills & Professions**
```ini
Rate.Skill.Discovery = 2.0
Rate.Skill.Gain.Gathering = 2.0
Rate.Skill.Gain.Crafting = 2.0
```

### **Rest & Regeneration** (Solo-friendly)
```ini
Rate.Rest.InGame = 2.0
Rate.Rest.Offline.InTavernOrCity = 3.0
Rate.Rest.Offline.InWilderness = 2.0
Rate.Health = 1.2
Rate.Mana = 1.2
```

### **Death & Durability** (Reduced penalties)
```ini
Rate.Corpse.Decay.Looted = 0.5
Death.SicknessLevel = 11
Rate.DurabilityLoss.OnDeath = 0.5
Rate.DurabilityLoss.OnDamage = 0.5
```

### **Mail & Quality of Life**
```ini
Mail.Delay.Player = 0      # Instant mail
Mail.Delay.GM = 0          # Instant mail
DungeonFinder.Enable = 1  # LFG enabled
Instance.UnloadDelay = 30  # Faster instance cleanup
```

### **Addon Channel** (Required for Progressive Systems addon)
```ini
# Enable addon messages for client-server communication
CONFIG_ADDON_CHANNEL = 1
```

### **Performance Settings**
```ini
# Optimize for progressive server
UpdateUptimeInterval = 10
MaxCoreStuckTime = 0
PlayerSave.Interval = 900000  # 15 minutes
PlayerSave.Stats.MinLevel = 1
```

---

## ✅ **MODULE CONFIGURATIONS**

### **mod-progressive-systems.conf**
Already optimized! See `modules/mod-progressive-systems/mod-progressive-systems.conf.dist`

### **mod-autobalance.conf**
```ini
AutoBalance.Enable = 1
AutoBalance.Solo.Difficulty = 0.35  # 35% difficulty for solo
AutoBalance.Solo.RewardXP = 1.2     # 20% bonus XP
AutoBalance.Solo.RewardMoney = 1.2  # 20% bonus money
AutoBalance.Group.Difficulty = 1.0  # Full difficulty for groups
```

### **mod-playerbots.conf**
```ini
AiPlayerbot.Enabled = 1
AiPlayerbot.MaxBots = 300
AiPlayerbot.RandomBotMaxLevel = 80
AiPlayerbot.RandomBotGearLimit = 3  # Rare quality
AiPlayerbot.RandomBotItemLevelLimit = 213  # Tier 7 Naxx
AiPlayerbot.ReactDelay = 80
AiPlayerbot.RandomBotAutoEquip = 1
AiPlayerbot.RandomBotAutoLearnSpells = 1
AiPlayerbot.RandomBotAutoPickTalents = 1
```

### **mod-solocraft.conf**
```ini
Solocraft.Enable = 0  # DISABLED - conflicts with autobalance
```

### **mod-instance-reset.conf**
```ini
InstanceReset.Enable = 0  # DISABLED - Progressive Systems has better reset
```

---

## 📋 **APPLYING CONFIGURATIONS**

1. **Copy worldserver.conf.dist to etc/worldserver.conf**
2. **Add the optimized settings above**
3. **Copy all module .conf.dist files to etc/**
4. **Edit module configs as needed**
5. **Restart server**

---

**All configs are optimized for:**
- ✅ Solo play viability
- ✅ Long-term progression
- ✅ Respecting player time
- ✅ Rewarding difficulty
- ✅ Performance

