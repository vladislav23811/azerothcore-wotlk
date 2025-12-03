# 🔄 Issue Automation System
## Systematic Pattern for Iterating Through Known Issues

**Created:** 2025-12-02  
**Purpose:** Provide a repeatable workflow for processing issues systematically

---

## 📊 ISSUE INVENTORY

### Current State
- **Code TODOs/FIXMEs:** 1,789 across 275 C++ files
- **Documented Issues:** 200+ in COMPREHENSIVE_FIX_TODO_LIST.md
- **Development Tasks:** Multiple phases in COMPREHENSIVE_ROADMAP.md
- **Status:** 7 issues fixed, 193+ remaining

---

## 🎯 ITERATION WORKFLOW

### Pattern 1: Fixed-Scope Batch Processing

Use this when you want to work on a specific category of issues:

```
PROMPT TEMPLATE:
"Process the next 5 issues from category [CATEGORY] in COMPREHENSIVE_FIX_TODO_LIST.md:
1. Read the issue description
2. Find the relevant code files
3. Implement the fix
4. Test the fix
5. Update the todo list to mark as complete
6. Document what was changed

Category: [Null Pointer Checks / Spell System / Combat System / etc.]
Start from: [N1 / S1 / M1 / etc.]"
```

**Example Usage:**
```
"Process the next 5 Null Pointer Check issues (N1-N5) from COMPREHENSIVE_FIX_TODO_LIST.md.
For each issue:
- Find all locations where the check is needed
- Add proper null checks
- Add error logging
- Mark complete in the todo list"
```

---

### Pattern 2: Code-First TODO Sweeping

Use this to process actual TODO comments in the codebase:

```
PROMPT TEMPLATE:
"Find and fix the next 3 TODO/FIXME comments in [DIRECTORY]:
1. Search for TODO/FIXME comments
2. Analyze each comment
3. Determine if it's fixable now
4. If yes: implement the fix
5. If no: document why and what's needed
6. Remove or update the comment
7. Log the resolution

Directory: [src/server/game/Spells / src/server/game/Handlers / etc.]"
```

**Example Usage:**
```
"Find the next 3 TODO comments in src/server/game/Spells/:
- Read the TODO comment
- Understand what needs to be done
- Implement the fix if possible
- If not fixable, add detailed explanation why
- Remove the TODO or replace with better comment"
```

---

### Pattern 3: File-by-File Deep Dive

Use this for thorough file cleanup:

```
PROMPT TEMPLATE:
"Deep dive into [FILENAME]:
1. Read the entire file
2. Find all TODO/FIXME/HACK/BUG comments
3. Fix each issue in order
4. Look for related issues not commented
5. Refactor if needed
6. Test changes
7. Document all fixes"
```

**Example Usage:**
```
"Deep dive into src/server/game/Spells/Spell.cpp:
- It has 26 TODO/FIXME comments
- Fix all of them in one session
- Look for similar issues nearby
- Ensure all fixes work together
- Update documentation"
```

---

### Pattern 4: Priority-Based Processing

Use this to focus on the most critical issues:

```
PROMPT TEMPLATE:
"Process [NUMBER] issues from Priority [LEVEL]:
1. Review priority level issues in COMPREHENSIVE_FIX_TODO_LIST.md
2. Assess impact and difficulty
3. Start with highest impact / lowest difficulty
4. Implement fixes
5. Test thoroughly
6. Mark complete
7. Generate summary report

Priority: [1-11]
Count: [1-10]"
```

**Example Usage:**
```
"Process 3 issues from Priority 1 (Critical Crash Fixes):
- Focus on null pointer checks
- Add defensive programming
- Ensure no regressions
- Test edge cases"
```

---

## 🤖 AUTOMATION COMMANDS

### Command 1: Next Issue
```
"Continue working on the next issue in COMPREHENSIVE_FIX_TODO_LIST.md.
Start from where we left off. Process 1 issue completely."
```

### Command 2: Next Batch
```
"Process the next batch of 5 issues from the current priority level."
```

### Command 3: Quick Sweep
```
"Do a quick sweep of [FILENAME] - fix all simple TODO comments
that can be done in <5 minutes each."
```

### Command 4: Deep Fix
```
"Take on the next complex issue - spend whatever time needed
to implement it properly with tests and documentation."
```

### Command 5: Status Report
```
"Generate a status report:
- How many issues fixed today
- How many issues remain in current priority
- Progress percentage
- Next recommended focus area"
```

---

## 📋 ISSUE CATEGORIZATION

### By Difficulty
- **🟢 EASY (5-15 min):** Simple null checks, logging additions, comment updates
- **🟡 MEDIUM (30-60 min):** Logic fixes, calculation corrections, validation additions
- **🔴 HARD (2-4 hours):** System refactors, major bug fixes, new functionality

### By Type
- **CRASH:** Null pointers, array bounds, memory issues
- **LOGIC:** Wrong calculations, incorrect behavior
- **INCOMPLETE:** Stubbed functions, placeholder code
- **OPTIMIZATION:** Performance improvements
- **CLEANUP:** Code quality, readability

### By System
- Spell System (289 TODOs)
- Player System (91 TODOs)
- Creature AI (63 TODOs)
- Combat System (62 TODOs)
- Handlers (150+ TODOs)
- Others

---

## 🔄 SESSION WORKFLOW

### Starting a Session

1. **Check Current Status**
```
"What's the current status of issue resolution?
Show me:
- Last issue worked on
- Current priority level
- Issues completed today
- Next recommended issue"
```

2. **Set Session Goal**
```
"Today I want to work on [CATEGORY] issues.
Process [COUNT] issues in this session."
```

3. **Begin Processing**
Follow one of the patterns above

### During Session

4. **Track Progress**
- Each issue completed is marked in COMPREHENSIVE_FIX_TODO_LIST.md
- Changes are documented
- Tests are performed

5. **Handle Blockers**
If an issue can't be completed:
- Document why
- Add to separate "BLOCKED_ISSUES.md"
- Move to next issue

### Ending Session

6. **Generate Summary**
```
"Generate an end-of-session summary:
- Issues attempted: [count]
- Issues completed: [count]
- Issues blocked: [count]
- Files modified: [list]
- Next session should start with: [issue ID]"
```

7. **Save Progress**
All changes committed, lists updated

---

## 📈 PROGRESS TRACKING

### Daily Log Format

Create `ISSUE_RESOLUTION_LOG.md`:

```markdown
## 2025-12-02

### Session 1 (Morning)
- **Goal:** Fix Priority 1 null checks (N1-N5)
- **Completed:** N1, N2, N3
- **Blocked:** N4 (requires database schema change)
- **Files Changed:** 
  - src/server/game/Spells/SpellInfo.cpp
  - src/server/game/Entities/Item/Item.cpp
  - src/server/game/Entities/Creature/Creature.cpp
- **Next:** Continue with N5

### Session 2 (Afternoon)
- ...
```

---

## 🎯 SMART BATCHING

### Grouping Strategy

When processing multiple issues, group by:

1. **Location:** All issues in same file/directory
2. **Type:** All null checks, all spell fixes, etc.
3. **System:** All combat, all quest, etc.
4. **Difficulty:** All easy, all medium, etc.

### Example Batches

**Batch 1: Spell System Null Checks**
```
- S1: Fix spell range null check
- SE1: Fix spell effect validation
- SM1: Fix spell school immunity null check
Location: src/server/game/Spells/
Time: ~2 hours
```

**Batch 2: Player Handler TODOs**
```
- All TODO comments in src/server/game/Handlers/CharacterHandler.cpp
- Count: 10 comments
- Type: Mixed (logging, validation, cleanup)
Time: ~3 hours
```

---

## 🔧 HELPER SCRIPTS

### Script 1: Extract TODOs

Create `extract_todos.ps1`:

```powershell
# Extract all TODOs from C++ files
$pattern = "TODO|FIXME|XXX|HACK|BUG"
$results = @()

Get-ChildItem -Path "src" -Filter "*.cpp" -Recurse | ForEach-Object {
    $file = $_.FullName
    $lineNum = 0
    Get-Content $file | ForEach-Object {
        $lineNum++
        if ($_ -match $pattern) {
            $results += [PSCustomObject]@{
                File = $file
                Line = $lineNum
                Content = $_.Trim()
            }
        }
    }
}

$results | Export-Csv "TODO_LIST.csv" -NoTypeInformation
Write-Host "Exported $($results.Count) TODOs to TODO_LIST.csv"
```

### Script 2: Count by System

Create `count_todos_by_system.ps1`:

```powershell
# Count TODOs by system
$systems = @{
    "Spells" = "src/server/game/Spells"
    "Combat" = "src/server/game/Combat"
    "Player" = "src/server/game/Entities/Player"
    "Creature" = "src/server/game/Entities/Creature"
    "Handlers" = "src/server/game/Handlers"
    "Scripts" = "src/server/scripts"
}

foreach ($system in $systems.Keys) {
    $path = $systems[$system]
    if (Test-Path $path) {
        $count = (Select-String -Path "$path\*.cpp" -Pattern "TODO|FIXME|HACK|BUG" -AllMatches).Matches.Count
        Write-Host "$system: $count TODOs"
    }
}
```

---

## 💡 BEST PRACTICES

### 1. One Issue at a Time
- Complete one issue fully before moving to next
- Don't leave half-fixed issues
- Test each fix individually

### 2. Document Everything
- Update todo list immediately
- Document what changed and why
- Note any side effects

### 3. Test Thoroughly
- Test the fix
- Test related functionality
- Look for regressions

### 4. Group Related Fixes
- Fix all similar issues together
- Maintain consistency
- Reduce context switching

### 5. Handle Technical Debt
- Don't just fix the symptom
- Fix the root cause
- Refactor if needed

---

## 🚀 QUICK START

### For Your Next Session

**Option A: Continue Priority 1**
```
"Continue working on Priority 1: Critical Crash Fixes from COMPREHENSIVE_FIX_TODO_LIST.md.
Start with the next unchecked item (N1). Process 3 issues."
```

**Option B: Sweep Spell System**
```
"Let's clean up the Spell system. Find the next 5 TODO comments in 
src/server/game/Spells/ and fix them one by one."
```

**Option C: File Deep Dive**
```
"Deep dive into src/server/game/Spells/Spell.cpp (has 26 TODOs).
Fix as many as possible in one session."
```

---

## 📊 METRICS TO TRACK

- Issues resolved per session
- Average time per issue
- Success rate (completed vs blocked)
- Files touched per session
- Most problematic systems
- Most common issue types

---

## 🎯 ULTIMATE GOAL

**Zero TODOs in Critical Systems:**
- Spells
- Combat
- Player
- Creatures
- Handlers

**Target: 6 months** at ~10 issues per week = ~260 issues

---

## 📝 NOTES

- Don't rush - quality over quantity
- Some TODOs are valid future work notes
- Focus on bugs and crashes first
- Leave optimization TODOs for later
- Maintain test coverage
- Keep building and running
- Document tricky decisions

---

**Use this document as your guide for every issue-fixing session!**

