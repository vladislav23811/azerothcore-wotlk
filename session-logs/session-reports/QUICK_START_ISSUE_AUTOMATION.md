# 🚀 Quick Start: Issue Automation

**5-Minute Setup Guide**

---

## Step 1: Generate Issue Tracker (One-time setup)

```powershell
# Run from project root
.\tools\extract_todos.ps1
```

This creates `TODO_TRACKER.csv` with all 1,789 issues catalogued.

---

## Step 2: Check Your Progress

```powershell
# View statistics
.\tools\issue_progress.ps1 -Stats

# Get next recommended issue
.\tools\issue_progress.ps1 -NextIssue

# Get next easy Spell System issue
.\tools\issue_progress.ps1 -NextIssue -System Spells -Difficulty LOW
```

---

## Step 3: Choose Your Workflow

### 🎯 Option A: Single Issue (Recommended for starting)

1. **Get next issue:**
   ```powershell
   .\tools\issue_progress.ps1 -NextIssue
   ```

2. **Tell Cursor to fix it:**
   ```
   "Fix issue ISSUE-123:
   - File: [file from command output]
   - Issue: [description from command output]
   - Implement the fix, test it, and update TODO_TRACKER.csv status to COMPLETED"
   ```

3. **Mark complete:**
   ```powershell
   .\tools\issue_progress.ps1 -MarkComplete ISSUE-123
   ```

---

### 🔄 Option B: Batch Processing (5 issues at once)

1. **Generate batch prompt:**
   ```powershell
   # All easy issues
   .\tools\batch_process.ps1 -Count 5 -Difficulty LOW
   
   # Spell system issues
   .\tools\batch_process.ps1 -Count 5 -System Spells
   
   # Easy spell issues
   .\tools\batch_process.ps1 -Count 3 -System Spells -Difficulty LOW
   ```

2. **Copy the generated prompt** from `batch_prompt.txt`

3. **Paste into Cursor** and let it process all issues

4. **Check progress:**
   ```powershell
   .\tools\issue_progress.ps1 -Stats
   ```

---

### 📋 Option C: Use Documented Lists

**Tell Cursor:**
```
"Process the next 5 issues from Priority 1 in COMPREHENSIVE_FIX_TODO_LIST.md.
Start with N1 (Null Pointer Checks). For each:
1. Find all locations needing the check
2. Add null checks with error logging
3. Mark complete in the document
4. Update TODO_TRACKER.csv if related"
```

---

### 🎯 Option D: File Deep Dive

**For files with many TODOs:**
```
"Deep dive into src/server/game/Spells/Spell.cpp:
- Has 26 TODO/FIXME comments
- Fix all simple issues (5-10 min each)
- Document complex ones
- Update TODO_TRACKER.csv for all fixed issues"
```

---

## Recommended First Session

### Morning (2-3 hours): Easy Wins

```
"Generate batch prompt for 10 LOW difficulty issues and process them:

.\tools\batch_process.ps1 -Count 10 -Difficulty LOW

Goal: Build momentum with quick wins
- Focus on logging additions
- Comment updates
- Simple null checks
Mark all completed issues in TODO_TRACKER.csv"
```

### Afternoon (2-3 hours): System Focus

```
"Work on Priority 1: Critical Crash Fixes from COMPREHENSIVE_FIX_TODO_LIST.md

Process N1-N5 (Null Pointer Checks):
- GetSpellInfo() null checks
- GetItemTemplate() null checks
- GetCreatureTemplate() null checks
- GetQuestTemplate() null checks
- Spell effects array null checks

Add defensive programming everywhere."
```

---

## Daily Routine

### Start of Day
```powershell
# Check yesterday's progress
.\tools\issue_progress.ps1 -Stats

# Get today's target
.\tools\issue_progress.ps1 -NextIssue
```

### During Work
- Fix issues one at a time or in batches
- Update TODO_TRACKER.csv as you go
- Log progress in ISSUE_RESOLUTION_LOG.md

### End of Day
```powershell
# Review progress
.\tools\issue_progress.ps1 -Stats

# Plan tomorrow
.\tools\issue_progress.ps1 -NextIssue
```

---

## Copy-Paste Prompts

### Prompt 1: Continue Where I Left Off
```
"Continue working on issues from TODO_TRACKER.csv. 
Get the next pending issue and fix it completely.
Mark it as COMPLETED when done."
```

### Prompt 2: Process Priority List
```
"Work through COMPREHENSIVE_FIX_TODO_LIST.md Priority 1.
Process the next 3 unchecked items.
Update both the TODO list and TODO_TRACKER.csv."
```

### Prompt 3: System Cleanup
```
"Clean up the [Spells/Combat/Player] system.
Find and fix the next 5 TODO comments in that system.
Update TODO_TRACKER.csv for each fix."
```

### Prompt 4: Quick Sweep
```
"Do a quick sweep of LOW difficulty issues.
Process as many as possible in 30 minutes.
Focus on simple wins - logging, comments, obvious fixes."
```

### Prompt 5: Deep Focus
```
"Take on a complex issue from Priority [X].
Spend whatever time needed to fix it properly.
Include tests, documentation, and related fixes."
```

---

## Tips for Success

### ✅ DO
- Start with LOW difficulty issues to build momentum
- Focus on one system at a time (less context switching)
- Update tracking files immediately after each fix
- Test each fix before moving on
- Log your sessions in ISSUE_RESOLUTION_LOG.md

### ❌ DON'T
- Try to fix too many issues at once (max 5-10 per batch)
- Skip testing
- Leave issues half-finished
- Forget to update tracking files
- Work on random issues without a plan

---

## Tracking Your Progress

### Files to Maintain
1. **TODO_TRACKER.csv** - Auto-generated, update Status column
2. **COMPREHENSIVE_FIX_TODO_LIST.md** - Check off items as completed
3. **ISSUE_RESOLUTION_LOG.md** - Log each session manually

### Progress Metrics
- Run `.\tools\issue_progress.ps1 -Stats` daily
- Track completion rate
- Monitor which systems are done
- Celebrate milestones (100 issues, 50%, etc.)

---

## Example Session

```powershell
# Start
PS> .\tools\issue_progress.ps1 -Stats
# Shows: 1789 total, 0 completed, 1789 pending

PS> .\tools\batch_process.ps1 -Count 5 -Difficulty LOW
# Generates prompt for 5 easy issues

# Copy prompt to Cursor, work for 1 hour, fix 5 issues

# End
PS> .\tools\issue_progress.ps1 -Stats
# Shows: 1789 total, 5 completed (0.3%), 1784 pending

# Log session
# Open ISSUE_RESOLUTION_LOG.md and add entry
```

---

## Need Help?

### Common Issues

**Q: CSV not found**
```powershell
A: Run .\tools\extract_todos.ps1 first
```

**Q: How do I mark multiple issues complete?**
```powershell
A: Run the command for each:
.\tools\issue_progress.ps1 -MarkComplete ISSUE-123
.\tools\issue_progress.ps1 -MarkComplete ISSUE-124
# Or update CSV directly in Excel
```

**Q: How often should I regenerate the CSV?**
```
A: Once at start, then only if you need to refresh.
   The CSV is your working tracker - don't overwrite it!
```

**Q: What if I find new issues?**
```
A: Add them manually to TODO_TRACKER.csv or 
   COMPREHENSIVE_FIX_TODO_LIST.md
```

---

## Your First Command

**Right now, run this:**

```powershell
.\tools\extract_todos.ps1
```

Then tell Cursor:
```
"Show me the contents of TODO_TRACKER.csv, then recommend 
which issues I should start with."
```

---

**🎉 You're ready to automate issue fixing!**

