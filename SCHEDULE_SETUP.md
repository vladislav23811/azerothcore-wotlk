# How to Schedule Automatic Error Checking

This guide shows you how to set up automatic error checking that will notify you when new unfixable errors are detected.

## Option 1: Windows Task Scheduler (Recommended)

1. **Open Task Scheduler**
   - Press `Win + R`, type `taskschd.msc`, press Enter

2. **Create Basic Task**
   - Click "Create Basic Task" in the right panel
   - Name: "Check AzerothCore Errors"
   - Description: "Checks for unfixable errors in improvement loop"

3. **Set Trigger**
   - Choose "Daily" or "When I log on"
   - Set time (e.g., every hour or every 6 hours)

4. **Set Action**
   - Action: "Start a program"
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\servers\azerothcore-wotlk\auto_check_errors.ps1"`
   - Start in: `C:\servers\azerothcore-wotlk`

5. **Finish**
   - Review settings and click Finish

## Option 2: Run Manually

Simply run:
```powershell
.\auto_check_errors.ps1
```

## Option 3: Add to Improvement Loop

The improvement loop already checks for errors, but you can also run this separately.

## What Happens

1. Script checks `unfixable_errors.log` for new errors
2. If new errors found, generates `AI_FIX_REQUEST_[timestamp].txt`
3. You can then share that file with the AI assistant
4. AI will add fix logic to the script

## Quick AI Request

When errors are detected, you can simply say to the AI:
- "Fix the errors in unfixable_errors.log"
- "Add fix logic for the errors in the latest AI_FIX_REQUEST file"
- Or paste the contents of the request file

The AI will then update `improve_loop_enhanced.ps1` to handle those errors automatically!

