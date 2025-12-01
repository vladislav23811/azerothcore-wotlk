# Enhanced Continuous Improvement Loop Script
# Builds, fixes errors, modernizes code, and adds new features in a loop
# Incorporates WoW 3.3.5a backportable features

param(
    [switch]$MonitorAIFixRequests,  # Enable monitoring and auto-fixing of AI_FIX_REQUEST files
    [int]$AIFixCheckInterval = 30   # Check interval for AI_FIX_REQUEST files (seconds)
)

$ErrorActionPreference = "Continue"

# Setup Visual Studio environment first
Write-Host "Setting up Visual Studio environment..." -ForegroundColor Cyan
$setupScript = Join-Path $PSScriptRoot "setup_vs_env.ps1"
if (Test-Path $setupScript) {
    . $setupScript
} else {
    # Fallback: manually set critical paths
    $vsBasePath = "C:\Program Files\Microsoft Visual Studio\2026\Community\VC\Tools\MSVC"
    $msvcPath = $null
    if (Test-Path $vsBasePath) {
        $msvcVersions = Get-ChildItem $vsBasePath -Directory | Sort-Object Name -Descending
        if ($msvcVersions) {
            $msvcPath = $msvcVersions[0].FullName
        }
    }
    # Fallback to a common version if auto-detect fails
    if (-not $msvcPath) {
        $msvcPath = "C:\Program Files\Microsoft Visual Studio\2026\Community\VC\Tools\MSVC\14.50.35717"
    }
    if (Test-Path $msvcPath) {
        $includePath = Join-Path $msvcPath "include"
        $libPath = Join-Path $msvcPath "lib\x64"
        $binPath = Join-Path $msvcPath "bin\Hostx64\x64"
        
        if (Test-Path $includePath) {
            $env:INCLUDE = "$includePath;$env:INCLUDE"
        }
        if (Test-Path $libPath) {
            $env:LIB = "$libPath;$env:LIB"
        }
        if (Test-Path $binPath) {
            $env:PATH = "$binPath;$env:PATH"
        }
        Write-Host "Manually configured VS environment" -ForegroundColor Yellow
    }
}

$startTime = Get-Date
$maxDuration = New-TimeSpan -Days 365  # Run for a year (effectively infinite)
$buildDir = "var/build"
$iteration = 0
$consecutiveSuccessCount = 0
$featuresAdded = 0
$filesModernized = 0
$errorsFixed = 0
$aiRequestsGenerated = 0
$lastAIRequestTime = $null
$runContinuously = $true  # Flag to run continuously
$processedAIRequests = @{}  # Track processed AI request files to detect new ones
$script:lastAIFixCheckTime = $null  # Track last AI fix check time
$script:processedAIFixFiles = @{}  # Track processed AI fix files

# WoW 3.3.5a backportable features list
$backportableFeatures = @(
    "Transmog System",
    "Void Storage",
    "Account-wide Mounts",
    "Account-wide Pets",
    "Guild Perks",
    "Rated Battlegrounds",
    "Looking for Raid (LFR)",
    "Dungeon Finder Improvements",
    "Achievement Improvements",
    "Pet Battle System (simplified)",
    "Cross-Realm Zones",
    "Flexible Raid Sizes",
    "Personal Loot",
    "Bonus Roll System",
    "World Quest System (simplified)",
    "Artifact Power (simplified)",
    "Mythic+ Dungeons (simplified)",
    "Timewalking Improvements",
    "Collection UI Improvements",
    "Social Features"
)

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Enhanced Continuous Improvement Loop" -ForegroundColor Green
Write-Host "Target duration: 8 hours" -ForegroundColor Green
Write-Host "Start time: $startTime" -ForegroundColor Green
if ($MonitorAIFixRequests) {
    Write-Host "AI Fix Request Monitoring: ENABLED (check every $AIFixCheckInterval seconds)" -ForegroundColor Cyan
}
Write-Host "========================================`n" -ForegroundColor Magenta

function Build-Project {
    param([string]$Target = "all")
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Building target: $Target" -ForegroundColor Cyan
    
    try {
        $buildOutput = cmake --build $buildDir --config Debug --target $Target 2>&1
        $exitCode = $LASTEXITCODE
        
        # If exit code is not set, check if build output indicates success
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
        
        # Count errors
        $errorLines = $buildOutput | Select-String -Pattern "error C\d+:|fatal error" | Measure-Object
        $errorCount = $errorLines.Count
        
        # Count warnings
        $warningLines = $buildOutput | Select-String -Pattern "warning C\d+:" | Measure-Object
        $warningCount = $warningLines.Count
        
        return @{
            ExitCode = $exitCode
            ErrorCount = $errorCount
            WarningCount = $warningCount
            Output = $buildOutput
        }
    }
    catch {
        Write-Host "Build function error: $_" -ForegroundColor Red
        return @{
            ExitCode = 1
            ErrorCount = 1
            WarningCount = 0
            Output = @("Build function exception: $_")
        }
    }
}

function Extract-Errors {
    param([string[]]$BuildOutput)
    
    $errors = @()
    foreach ($line in $BuildOutput) {
        if ($line -match "error C\d+:" -or $line -match "fatal error") {
            $errors += $line
        }
    }
    return $errors
}

function Log-UnfixableError {
    param([string]$ErrorText, [string]$ErrorType)
    
    $logFile = "unfixable_errors.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @"
========================================
Timestamp: $timestamp
Error Type: $ErrorType
Error: $ErrorText
========================================

"@
    Add-Content -Path $logFile -Value $logEntry
    Write-Host "  Logged unfixable error to: $logFile" -ForegroundColor Yellow
    Write-Host "  Share this file with the AI to get fix logic added!" -ForegroundColor Cyan
}

function Generate-AIErrorReport {
    param([string[]]$Errors, [string[]]$BuildOutput)
    
    Write-Host "`n  [AI] Generating AI-ready error report..." -ForegroundColor Cyan
    
    $logFile = "unfixable_errors.log"
    if (-not (Test-Path $logFile) -or (Get-Item $logFile).Length -eq 0) {
        Write-Host "    No unfixable errors to report" -ForegroundColor Gray
        return $null
    }
    
    $errors = Get-Content $logFile -Raw
    $errorCount = ($errors -split "========================================").Count - 1
    
    if ($errorCount -eq 0) {
        return $null
    }
    
    # Extract error patterns for analysis
    $errorTypes = @()
    $missingHeaders = @()
    $errorPatterns = @()
    
    if ($errors -match "Error Type: (.+?)\r?\n") {
        $errorTypes = [regex]::Matches($errors, "Error Type: (.+?)\r?\n") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    }
    
    if ($errors -match "Cannot open include file: '(.+?)'") {
        $missingHeaders = [regex]::Matches($errors, "Cannot open include file: '(.+?)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    }
    
    # Extract C++ error codes
    if ($errors -match "error C(\d+):") {
        $errorPatterns = [regex]::Matches($errors, "error C(\d+):") | ForEach-Object { "C$($_.Groups[1].Value)" } | Select-Object -Unique
    }
    
    # Generate comprehensive AI request
    $requestFile = "AI_FIX_REQUEST_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $request = @"
========================================
AUTOMATED ERROR FIX REQUEST FOR AI
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Project: AzerothCore WotLK
Total Unfixable Errors: $errorCount

ERROR SUMMARY:
=============
Unique Error Types: $($errorTypes.Count)
  $($errorTypes | ForEach-Object { "  - $_" } | Out-String)

Missing Headers Detected: $($missingHeaders.Count)
  $($missingHeaders | ForEach-Object { "  - $_" } | Out-String)

C++ Error Codes: $($errorPatterns.Count)
  $($errorPatterns | ForEach-Object { "  - $_" } | Out-String)

FULL ERROR LOG:
===============
$errors

RECENT BUILD OUTPUT (Last 50 lines):
=====================================
$($BuildOutput | Select-Object -Last 50 | Out-String)

REQUEST FOR AI:
===============
Please analyze the errors above and add automatic fix logic to the 
Fix-CommonErrors function in improve_loop_enhanced.ps1.

For each error type:
1. Identify the pattern
2. Add appropriate fix logic to the switch statement or error handling
3. Test the fix logic if possible

The script is located at: improve_loop_enhanced.ps1
The Fix-CommonErrors function starts around line 153.

Please provide the updated function code that handles these errors automatically.

========================================
"@
    
    Set-Content -Path $requestFile -Value $request
    
    # Create a ready-to-use prompt file for automatic AI communication
    $promptFile = "AI_PROMPT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $readyPrompt = @"
Please analyze and fix the compilation errors in the AzerothCore WotLK project.

The errors are documented in: $requestFile
Full error log: unfixable_errors.log

ERROR SUMMARY:
- Total unfixable errors: $errorCount
- Error types: $($errorTypes -join ', ')
- Missing headers: $($missingHeaders -join ', ')
- C++ error codes: $($errorPatterns -join ', ')

ACTION REQUIRED:
Add automatic fix logic to the Fix-CommonErrors function in improve_loop_enhanced.ps1 (starts around line 153).

For each error pattern found:
1. Identify the error pattern
2. Add appropriate fix logic to handle it automatically
3. Ensure the fix is added to the switch statement or error handling section

The script should automatically fix these errors in future iterations.

Please read the full error details from: $requestFile
"@
    
    Set-Content -Path $promptFile -Value $readyPrompt
    
    # Create a JSON file for programmatic access
    $jsonFile = "AI_REQUEST_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $jsonData = @{
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        errorCount = $errorCount
        errorTypes = @($errorTypes)
        missingHeaders = @($missingHeaders)
        errorCodes = @($errorPatterns)
        requestFile = $requestFile
        promptFile = $promptFile
        logFile = "unfixable_errors.log"
        scriptFile = "improve_loop_enhanced.ps1"
        functionName = "Fix-CommonErrors"
        functionLine = 153
        action = "Add automatic fix logic to handle these errors"
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $jsonFile -Value $jsonData
    
    Write-Host "    AI request generated: $requestFile" -ForegroundColor Green
    Write-Host "    Ready-to-use prompt: $promptFile" -ForegroundColor Cyan
    Write-Host "    JSON data file: $jsonFile" -ForegroundColor Cyan
    
    # Create a marker file that indicates AI assistance is needed
    $markerFile = ".ai_assistance_needed"
    Set-Content -Path $markerFile -Value @"
AI_ASSISTANCE_REQUESTED
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Request File: $requestFile
Prompt File: $promptFile
JSON File: $jsonFile
Error Count: $errorCount
"@
    
    Write-Host "    Marker file created: $markerFile (AI can detect this automatically)" -ForegroundColor Magenta
    
    return $requestFile
}

function Create-AIAutoPrompt {
    param([string]$RequestFile, [string]$PromptFile)
    
    # Create a simple one-liner prompt that can be easily shared
    $autoPrompt = "Read $PromptFile and fix the compilation errors. Add automatic fix logic to the Fix-CommonErrors function in improve_loop_enhanced.ps1."
    
    $autoPromptFile = "AUTO_PROMPT.txt"
    Set-Content -Path $autoPromptFile -Value $autoPrompt
    
    Write-Host "  [AI] Auto-prompt created: $autoPromptFile" -ForegroundColor Magenta
    Write-Host "  [AI] Content: $autoPrompt" -ForegroundColor Gray
    
    return $autoPromptFile
}

function Request-AIAssistance {
    param([string[]]$Errors, [string[]]$BuildOutput)
    
    # Prevent spam - only generate new request if it's been more than 5 minutes since last request
    $now = Get-Date
    if ($script:lastAIRequestTime -ne $null) {
        $timeSinceLastRequest = $now - $script:lastAIRequestTime
        if ($timeSinceLastRequest.TotalMinutes -lt 5) {
            Write-Host "  [AI] AI request generated recently. Skipping to avoid spam." -ForegroundColor Gray
            Write-Host "  [AI] Last request: $($script:lastAIRequestTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
            return
        }
    }
    
    Write-Host "`n  [AI] ========================================" -ForegroundColor Magenta
    Write-Host "  [AI] REQUESTING AI ASSISTANCE" -ForegroundColor Magenta
    Write-Host "  [AI] ========================================" -ForegroundColor Magenta
    
    # Generate the error report
    $reportFile = Generate-AIErrorReport -Errors $Errors -BuildOutput $BuildOutput
    
    if ($reportFile) {
        $script:aiRequestsGenerated++
        $script:lastAIRequestTime = $now
        
        # Find the prompt file that was just created
        $promptFiles = Get-ChildItem -Path "." -Filter "AI_PROMPT_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $jsonFiles = Get-ChildItem -Path "." -Filter "AI_REQUEST_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        Write-Host "`n  [AI] Error report ready: $reportFile" -ForegroundColor Cyan
        Write-Host "  [AI] Total AI requests this session: $script:aiRequestsGenerated" -ForegroundColor Cyan
        
        if ($promptFiles) {
            $promptContent = Get-Content $promptFiles.FullName -Raw
            
            # Create auto-prompt file
            $autoPromptFile = Create-AIAutoPrompt -RequestFile $reportFile -PromptFile $promptFiles.Name
            
            Write-Host "`n  [AI] ========================================" -ForegroundColor Green
            Write-Host "  [AI] READY-TO-USE PROMPT (Copy & Paste Below):" -ForegroundColor Green
            Write-Host "  [AI] ========================================" -ForegroundColor Green
            Write-Host "`n$promptContent`n" -ForegroundColor White
            Write-Host "  [AI] ========================================" -ForegroundColor Green
            Write-Host "`n  [AI] EASIEST WAY - Just say:" -ForegroundColor Yellow
            Write-Host "      'Read $($promptFiles.Name) and fix the errors'" -ForegroundColor Cyan
            Write-Host "  OR" -ForegroundColor Gray
            Write-Host "      Copy the prompt above and paste it here!" -ForegroundColor Cyan
        }
        
        Write-Host "`n  [AI] Files created:" -ForegroundColor Yellow
        Write-Host "    - Request file: $reportFile" -ForegroundColor White
        if ($promptFiles) {
            Write-Host "    - Prompt file: $($promptFiles.Name)" -ForegroundColor White
        }
        if ($jsonFiles) {
            Write-Host "    - JSON data: $($jsonFiles.Name)" -ForegroundColor White
        }
        Write-Host "    - Marker file: .ai_assistance_needed (for auto-detection)" -ForegroundColor White
        
        Write-Host "`n  [AI] Quick commands you can use:" -ForegroundColor Yellow
        Write-Host "    - 'Read $($promptFiles.Name) and fix the errors'" -ForegroundColor Cyan
        Write-Host "    - 'Fix the errors in unfixable_errors.log'" -ForegroundColor Cyan
        Write-Host "    - 'Add fix logic for errors in $reportFile'" -ForegroundColor Cyan
        Write-Host "`n  [AI] The AI will automatically analyze and add fix logic!" -ForegroundColor Green
        
        # Also display a summary in the console
        Write-Host "`n  [AI] Quick Summary:" -ForegroundColor Cyan
        $logFile = "unfixable_errors.log"
        if (Test-Path $logFile) {
            $errorContent = Get-Content $logFile -Raw
            $errorCount = ($errorContent -split "========================================").Count - 1
            Write-Host "    - Unfixable errors: $errorCount" -ForegroundColor Yellow
            
            if ($errorContent -match "Cannot open include file: '(.+?)'") {
                $headers = [regex]::Matches($errorContent, "Cannot open include file: '(.+?)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
                Write-Host "    - Missing headers: $($headers -join ', ')" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "  [AI] No unfixable errors to report - all errors are being handled!" -ForegroundColor Green
    }
    
    Write-Host "  [AI] ========================================`n" -ForegroundColor Magenta
}

function Fix-CommonErrors {
    param([string[]]$Errors)
    
    $fixed = 0
    $unfixableErrors = @()
    
    # Check if it's a header path issue - re-run environment setup
    $headerErrors = $Errors | Where-Object { $_ -match "crtdbg\.h|stddef\.h|math\.h|stdlib\.h|winapifamily\.h" }
    if ($headerErrors.Count -gt 0) {
        Write-Host "  Detected header path errors - re-running environment setup..." -ForegroundColor Yellow
        $setupScript = Join-Path $PSScriptRoot "setup_vs_env.ps1"
        if (Test-Path $setupScript) {
            . $setupScript | Out-Null
            $fixed++
            Write-Host "    Fixed: Re-ran VS environment setup" -ForegroundColor Green
        }
    }
    
    foreach ($error in $Errors) {
        # Fix missing header includes
        if ($error -match "Cannot open include file: '(\w+)'") {
            $missingHeader = $matches[1]
            Write-Host "  Detected missing header: $missingHeader" -ForegroundColor Yellow
            
            # Try to fix common missing headers
            switch ($missingHeader) {
                "string" {
                    # Check if it's in Common.h
                    $commonFile = "src/common/Common.h"
                    if (Test-Path $commonFile) {
                        $content = Get-Content $commonFile -Raw
                        if ($content -notmatch "#include\s*<string>") {
                            $content = $content -replace '(#include\s*"Define\.h")', "`$1`n#include <string>"
                            Set-Content -Path $commonFile -Value $content -NoNewline
                            $fixed++
                            Write-Host "    Fixed: Added <string> to Common.h" -ForegroundColor Green
                        }
                    }
                }
                "future" {
                    # Already handled in DatabaseEnvFwd.h
                    Write-Host "    Note: future header should be handled" -ForegroundColor Gray
                }
                "type_traits" {
                    # Try to add to EnumFlag.h
                    $enumFile = "src/common/Utilities/EnumFlag.h"
                    if (Test-Path $enumFile) {
                        $content = Get-Content $enumFile -Raw
                        if ($content -notmatch "#include\s*<type_traits>") {
                            # Add after other includes
                            $content = $content -replace '(#include\s*[<"].*?[>"])', "`$1`n#include <type_traits>"
                            Set-Content -Path $enumFile -Value $content -NoNewline
                            $fixed++
                            Write-Host "    Fixed: Added <type_traits> to EnumFlag.h" -ForegroundColor Green
                        }
                    }
                }
                default {
                    # Unknown error type - log it for AI analysis
                    $unfixableErrors += $error
                    Log-UnfixableError -ErrorText $error -ErrorType "Missing Header: $missingHeader"
                }
            }
        }
        # Fix redefinition errors (C2374, C2086)
        elseif ($error -match "error C(2374|2086):\s*'([^']+)':\s*redefinition") {
            $symbolName = $matches[2]
            $errorCode = $matches[1]
            Write-Host "  Detected redefinition error: $symbolName (C$errorCode)" -ForegroundColor Yellow
            
            # Extract file path from error
            if ($error -match "([A-Z]:[^\(]+)\((\d+)\):") {
                $filePath = $matches[1]
                $lineNumber = [int]$matches[2]
                
                if (Test-Path $filePath) {
                    $content = Get-Content $filePath -Raw
                    $lines = Get-Content $filePath
                    
                    # Find the line with the redefinition
                    if ($lineNumber -le $lines.Count) {
                        $problemLine = $lines[$lineNumber - 1]
                        
                        # Check if it's a constexpr or const definition
                        if ($problemLine -match "(constexpr|const)\s+\w+\s+$symbolName\s*=") {
                            # Make it static to avoid redefinition across translation units
                            if ($problemLine -notmatch "static\s+(constexpr|const)") {
                                $fixedLine = $problemLine -replace "(constexpr|const)", "static `$1"
                                $lines[$lineNumber - 1] = $fixedLine
                                $newContent = $lines -join "`n"
                                Set-Content -Path $filePath -Value $newContent -NoNewline
                                $fixed++
                                Write-Host "    Fixed: Made $symbolName static in $filePath" -ForegroundColor Green
                            }
                            else {
                                # Already static, might be a duplicate - check if we can remove it
                                Write-Host "    Note: $symbolName is already static, may need manual review" -ForegroundColor Gray
                                $unfixableErrors += $error
                                Log-UnfixableError -ErrorText $error -ErrorType "Redefinition: $symbolName (already static)"
                            }
                        }
                        else {
                            # Try to find and fix the definition
                            Write-Host "    Attempting to fix redefinition of $symbolName..." -ForegroundColor Yellow
                            $unfixableErrors += $error
                            Log-UnfixableError -ErrorText $error -ErrorType "Redefinition: $symbolName"
                        }
                    }
                }
            }
            else {
                $unfixableErrors += $error
                Log-UnfixableError -ErrorText $error -ErrorType "Redefinition: $symbolName"
            }
        }
        else {
            # Unknown error pattern - log it
            $unfixableErrors += $error
            Log-UnfixableError -ErrorText $error -ErrorType "Unknown Pattern"
        }
    }
    
    # If we have unfixable errors, try to auto-generate fixes
    if ($unfixableErrors.Count -gt 0) {
        Write-Host "`n  [!] Found $($unfixableErrors.Count) unfixable error(s)" -ForegroundColor Yellow
        
        # Try to auto-generate fix logic
        Write-Host "  [->] Attempting to auto-generate fix logic..." -ForegroundColor Cyan
        $autoFixScript = Join-Path $PSScriptRoot "auto_fix_generator.ps1"
        if (Test-Path $autoFixScript) {
            try {
                $fixResult = & $autoFixScript -Errors $unfixableErrors 2>&1
                Write-Host $fixResult
                Write-Host "  [OK] Auto-fix generation attempted!" -ForegroundColor Green
                Write-Host "  [->] Note: Please rebuild to test new fix logic" -ForegroundColor Yellow
                # Don't recursively call to avoid infinite loops - user should rebuild instead
            }
            catch {
                Write-Host "  [!] Auto-fix generation failed: $_" -ForegroundColor Red
            }
        }
        
        # Log errors for manual review if auto-fix didn't work
        if ($unfixableErrors.Count -gt 0) {
            Write-Host "  [!] Errors logged to: unfixable_errors.log" -ForegroundColor Yellow
            
            # Automatically generate AI request
            $script:aiRequestGenerated = $true
            Request-AIAssistance -Errors $unfixableErrors -BuildOutput $buildResult.Output
        }
    }
    
    return $fixed
}

function Modernize-CppFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    $modified = $false
    
    # Modernize C++ patterns
    # 1. Replace NULL with nullptr (but not in strings/comments)
    if ($content -match '\bNULL\b' -and $content -notmatch '".*NULL.*"') {
        # Be more careful - only replace NULL that's not in strings
        $lines = $content -split "`n"
        $newLines = @()
        foreach ($line in $lines) {
            if ($line -match '\bNULL\b' -and $line -notmatch '".*NULL.*"') {
                $newLine = $line -replace '\bNULL\b', 'nullptr'
                $newLines += $newLine
                $modified = $true
            }
            else {
                $newLines += $line
            }
        }
        if ($modified) {
            $content = $newLines -join "`n"
        }
    }
    
    if ($modified -and $content -ne $originalContent) {
        Set-Content -Path $FilePath -Value $content -NoNewline
        return $true
    }
    
    return $false
}

function Modernize-Code {
    param([int]$MaxFiles = 10)
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting code modernization..." -ForegroundColor Yellow
    
    # Find C++ files in modules (prioritize mod-azerothshard)
    $cppFiles = Get-ChildItem -Path "modules" -Include *.cpp,*.h -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\var\\" -and $_.FullName -notmatch "\\_deps\\" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $MaxFiles
    
    $modernized = 0
    foreach ($file in $cppFiles) {
        Write-Host "  Modernizing: $($file.Name)" -ForegroundColor Gray
        if (Modernize-CppFile -FilePath $file.FullName) {
            $modernized++
            $script:filesModernized++
        }
    }
    
    Write-Host "Modernized $modernized files" -ForegroundColor Yellow
    return $modernized
}

function Add-NewFeature {
    param([string]$FeatureName)
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Adding feature: $FeatureName" -ForegroundColor Green
    
    # Create feature directory structure
    $featureDir = "modules/mod-azerothshard/src/Features/$($FeatureName -replace ' ', '')"
    if (-not (Test-Path $featureDir)) {
        New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
    }
    
    # Create basic feature files
    $headerFile = Join-Path $featureDir "$($FeatureName -replace ' ', '').h"
    $sourceFile = Join-Path $featureDir "$($FeatureName -replace ' ', '').cpp"
    
    if (-not (Test-Path $headerFile)) {
        # Build class name without spaces
        $className = $FeatureName -replace ' ', ''
        $classNameUpper = ($FeatureName -replace ' ', '_').ToUpper()
        
        # Build header content with string replacement to avoid PowerShell parsing C++ code
        $headerContent = @'
/*
 * {FEATURE_NAME} Feature
 * Backported from newer WoW patches for 3.3.5a compatibility
 */

#ifndef {CLASS_NAME_UPPER}_H
#define {CLASS_NAME_UPPER}_H

#include "Define.h"
#include "Common.h"

class {CLASS_NAME}
{
public:
    static {CLASS_NAME}* instance();
    
    void Initialize();
    void Update(uint32 diff);
    
private:
    {CLASS_NAME}() = default;
    ~{CLASS_NAME}() = default;
};

#define s{CLASS_NAME} {CLASS_NAME}::instance()

#endif
'@
        $headerContent = $headerContent -replace '{FEATURE_NAME}', $FeatureName
        $headerContent = $headerContent -replace '{CLASS_NAME}', $className
        $headerContent = $headerContent -replace '{CLASS_NAME_UPPER}', $classNameUpper
        Set-Content -Path $headerFile -Value $headerContent
    }
    
    if (-not (Test-Path $sourceFile)) {
        # Build class name without spaces
        $className = $FeatureName -replace ' ', ''
        
        # Build source content with string replacement
        $sourceContent = @'
/*
 * {FEATURE_NAME} Feature Implementation
 */

#include "{CLASS_NAME}.h"

{CLASS_NAME}* {CLASS_NAME}::instance()
{
    static {CLASS_NAME} instance;
    return &instance;
}

void {CLASS_NAME}::Initialize()
{
    // TODO: Initialize feature
}

void {CLASS_NAME}::Update(uint32 diff)
{
    // TODO: Update feature
}
'@
        $sourceContent = $sourceContent -replace '{FEATURE_NAME}', $FeatureName
        $sourceContent = $sourceContent -replace '{CLASS_NAME}', $className
        Set-Content -Path $sourceFile -Value $sourceContent
    }
    
    $script:featuresAdded++
    Write-Host "Feature '$FeatureName' structure created" -ForegroundColor Green
}

function Improve-ExistingFeatures {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Improving existing features..." -ForegroundColor Yellow
    
    # Find and improve existing feature files
    $featureFiles = Get-ChildItem -Path "modules/mod-azerothshard/src" -Include *.cpp,*.h -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\var\\" -and $_.FullName -notmatch "\\_deps\\" } |
        Select-Object -First 5
    
    foreach ($file in $featureFiles) {
        $content = Get-Content $file.FullName -Raw
        $original = $content
        
        # Add null pointer checks
        # Improve error handling
        # Add const correctness
        # Add documentation
        
        if ($content -ne $original) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "  Improved: $($file.Name)" -ForegroundColor Gray
        }
    }
}

function Add-WoWBackportFeature {
    # Select a random backportable feature
    $feature = $backportableFeatures | Get-Random
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Adding WoW backport feature: $feature" -ForegroundColor Cyan
    Add-NewFeature -FeatureName $feature
}

function Check-ForAIRequests {
    # Check for AI request files and read them in the loop
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking for AI request files..." -ForegroundColor Cyan
    
    $foundRequests = $false
    $newRequestsFound = $false
    
    # Check for all AI_FIX_REQUEST files and detect new ones
    $allRequestFiles = Get-ChildItem -Path "." -Filter "AI_FIX_REQUEST_*.txt" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if ($allRequestFiles) {
        Write-Host "  [AI] Found $($allRequestFiles.Count) AI_FIX_REQUEST file(s)" -ForegroundColor Green
        
        foreach ($requestFile in $allRequestFiles) {
            $fileKey = $requestFile.Name
            $isNew = -not $script:processedAIRequests.ContainsKey($fileKey)
            
            if ($isNew) {
                $newRequestsFound = $true
                $script:processedAIRequests[$fileKey] = $requestFile.LastWriteTime
                Write-Host "`n  [AI] ========================================" -ForegroundColor Magenta
                Write-Host "  [AI] NEW AI FIX REQUEST DETECTED!" -ForegroundColor Magenta
                Write-Host "  [AI] ========================================" -ForegroundColor Magenta
                Write-Host "  [AI] File: $($requestFile.Name)" -ForegroundColor Cyan
                Write-Host "  [AI] Created: $($requestFile.LastWriteTime)" -ForegroundColor Gray
                Write-Host "  [AI] Size: $([math]::Round($requestFile.Length / 1KB, 2)) KB" -ForegroundColor Gray
                
                # Read and display the full request content
                try {
                    $requestContent = Get-Content $requestFile.FullName -Raw
                    Write-Host "`n  [AI] ========================================" -ForegroundColor Yellow
                    Write-Host "  [AI] FULL REQUEST CONTENT:" -ForegroundColor Yellow
                    Write-Host "  [AI] ========================================" -ForegroundColor Yellow
                    Write-Host $requestContent -ForegroundColor White
                    Write-Host "  [AI] ========================================" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "  [AI] Error reading file: $_" -ForegroundColor Red
                }
                
                $foundRequests = $true
            }
            else {
                Write-Host "  [AI] Already processed: $fileKey" -ForegroundColor Gray
            }
        }
    }
    
    # Check for marker file
    if (Test-Path ".ai_assistance_needed") {
        Write-Host "  [AI] ========================================" -ForegroundColor Magenta
        Write-Host "  [AI] AI ASSISTANCE REQUESTED!" -ForegroundColor Magenta
        Write-Host "  [AI] ========================================" -ForegroundColor Magenta
        
        # Find the most recent AI_PROMPT file
        $promptFiles = Get-ChildItem -Path "." -Filter "AI_PROMPT_*.txt" -ErrorAction SilentlyContinue | 
            Sort-Object LastWriteTime -Descending
        
        if ($promptFiles) {
            $latestPrompt = $promptFiles | Select-Object -First 1
            Write-Host "`n  [AI] Found $($promptFiles.Count) prompt file(s)" -ForegroundColor Green
            Write-Host "  [AI] Reading latest: $($latestPrompt.Name)" -ForegroundColor Cyan
            Write-Host "  [AI] Created: $($latestPrompt.LastWriteTime)" -ForegroundColor Gray
            
            # Read and display the prompt content
            $promptContent = Get-Content $latestPrompt.FullName -Raw
            Write-Host "`n  [AI] ========================================" -ForegroundColor Yellow
            Write-Host "  [AI] PROMPT CONTENT:" -ForegroundColor Yellow
            Write-Host "  [AI] ========================================" -ForegroundColor Yellow
            Write-Host $promptContent -ForegroundColor White
            Write-Host "  [AI] ========================================" -ForegroundColor Yellow
            Write-Host "  [AI] File location: $($latestPrompt.FullName)" -ForegroundColor Gray
            
            $foundRequests = $true
            
            # Also check for JSON file
            $jsonFiles = Get-ChildItem -Path "." -Filter "AI_REQUEST_*.json" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
            
            if ($jsonFiles) {
                Write-Host "`n  [AI] Found JSON data file: $($jsonFiles.Name)" -ForegroundColor Green
                try {
                    $jsonData = Get-Content $jsonFiles.FullName -Raw | ConvertFrom-Json
                    Write-Host "  [AI] Error Summary:" -ForegroundColor Cyan
                    Write-Host "    - Total errors: $($jsonData.errorCount)" -ForegroundColor Yellow
                    Write-Host "    - Error types: $($jsonData.errorTypes -join ', ')" -ForegroundColor Yellow
                    if ($jsonData.missingHeaders) {
                        Write-Host "    - Missing headers: $($jsonData.missingHeaders -join ', ')" -ForegroundColor Yellow
                    }
                    if ($jsonData.errorCodes) {
                        Write-Host "    - C++ error codes: $($jsonData.errorCodes -join ', ')" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "  [AI] Could not parse JSON file: $_" -ForegroundColor Red
                }
            }
            
            # Check for request file
            $requestFiles = Get-ChildItem -Path "." -Filter "AI_FIX_REQUEST_*.txt" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
            
            if ($requestFiles) {
                Write-Host "`n  [AI] Found detailed request file: $($requestFiles.Name)" -ForegroundColor Green
                Write-Host "  [AI] This file contains full error details" -ForegroundColor Gray
            }
        }
        
        # Check for AUTO_PROMPT.txt
        if (Test-Path "AUTO_PROMPT.txt") {
            Write-Host "`n  [AI] AUTO_PROMPT.txt found!" -ForegroundColor Green
            $autoPrompt = Get-Content "AUTO_PROMPT.txt" -Raw
            Write-Host "  [AI] Auto-prompt: $autoPrompt" -ForegroundColor Cyan
            $foundRequests = $true
        }
        
        # Check for unfixable_errors.log
        if (Test-Path "unfixable_errors.log") {
            $logSize = (Get-Item "unfixable_errors.log").Length
            if ($logSize -gt 0) {
                Write-Host "`n  [AI] unfixable_errors.log found ($logSize bytes)" -ForegroundColor Green
                $errorCount = ((Get-Content "unfixable_errors.log" -Raw) -split "========================================").Count - 1
                Write-Host "  [AI] Contains approximately $errorCount error(s)" -ForegroundColor Yellow
                $foundRequests = $true
            }
        }
        
        if ($foundRequests) {
            Write-Host "`n  [AI] ========================================" -ForegroundColor Magenta
            Write-Host "  [AI] AI can now process these errors!" -ForegroundColor Magenta
            if ($latestPrompt) {
                Write-Host "  [AI] Say: 'Read $($latestPrompt.Name) and fix the errors'" -ForegroundColor Cyan
            }
            Write-Host "  [AI] Or: 'Fix the errors in unfixable_errors.log'" -ForegroundColor Cyan
            if ($newRequestsFound) {
                Write-Host "  [AI] NEW requests detected - ready for immediate processing!" -ForegroundColor Green
            }
            Write-Host "  [AI] ========================================`n" -ForegroundColor Magenta
        }
    }
    
    # Summary of all monitored files
    if ($allRequestFiles -or $foundRequests) {
        Write-Host "`n  [AI] Monitoring Summary:" -ForegroundColor Cyan
        Write-Host "    - Total AI_FIX_REQUEST files: $($allRequestFiles.Count)" -ForegroundColor White
        Write-Host "    - Processed files: $($script:processedAIRequests.Count)" -ForegroundColor White
        Write-Host "    - New files this iteration: $(if ($newRequestsFound) { 'YES' } else { 'No' })" -ForegroundColor $(if ($newRequestsFound) { 'Green' } else { 'Gray' })
    }
    else {
        Write-Host "  [AI] No AI assistance requests found" -ForegroundColor Gray
    }
    
    return ($foundRequests -or $newRequestsFound)
}

# Shared function to process AI_FIX_REQUEST files (also used by monitor_ai_fix_loop.ps1)
function Process-AIFixRequestFile {
    param(
        [string]$FilePath,
        [string]$WorkspaceRoot = $PSScriptRoot
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "  [AI] File not found: $FilePath" -ForegroundColor Red
        return @{ Fixed = $false; ErrorsFound = 0 }
    }
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
    }
    catch {
        Write-Host "  [AI] Error reading file: $_" -ForegroundColor Red
        return @{ Fixed = $false; ErrorsFound = 0 }
    }
    
    $fixed = $false
    $errorsFound = 0
    
    # Enhanced error pattern matching
    $errorPatterns = @(
        "error\s+C(\d+):\s*(.+)",  # Standard MSVC error
        "error:\s*(.+)",  # Generic error
        "fatal\s+error\s+C(\d+):\s*(.+)"  # Fatal error
    )
    
    $errors = @()
    foreach ($pattern in $errorPatterns) {
        $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $matches) {
            $errorCode = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { "UNKNOWN" }
            $errorMsg = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $match.Groups[1].Value }
            $errors += @{
                Code = $errorCode
                Message = $errorMsg
                FullMatch = $match.Value
            }
            $errorsFound++
        }
    }
    
    Write-Host "  [AI] Found $errorsFound error(s) in request file" -ForegroundColor Cyan
    
    # Fix BATTLEGROUND_QUEUE_1v1 redefinition errors
    if ($content -match "BATTLEGROUND_QUEUE_1v1.*redefinition") {
        Write-Host "  [AI] Fixing BATTLEGROUND_QUEUE_1v1 redefinition errors..." -ForegroundColor Cyan
        
        $azthHeader = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH.h"
        $azthCpp = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH.cpp"
        $azthScCpp = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH_SC.cpp"
        
        # Check and fix AZTH.cpp
        if (Test-Path $azthCpp) {
            $cppContent = Get-Content $azthCpp -Raw
            if ($cppContent -match "static constexpr uint32 BATTLEGROUND_QUEUE_1v1") {
                Write-Host "    [AI] Removing duplicate definition from AZTH.cpp..." -ForegroundColor Yellow
                $cppContent = $cppContent -replace "(?s)// 1v1 Arena constants.*?static constexpr uint32 BATTLEGROUND_QUEUE_1v1 = 11;", "// 1v1 Arena constants are now defined in AZTH.h`nusing namespace AzthArenaConstants;"
                Set-Content -Path $azthCpp -Value $cppContent -NoNewline
                $fixed = $true
            }
        }
        
        # Check and fix AZTH_SC.cpp
        if (Test-Path $azthScCpp) {
            $scContent = Get-Content $azthScCpp -Raw
            if ($scContent -match "static constexpr uint32 BATTLEGROUND_QUEUE_1v1") {
                Write-Host "    [AI] Removing duplicate definition from AZTH_SC.cpp..." -ForegroundColor Yellow
                $scContent = $scContent -replace "(?s)// 1v1 Arena constants.*?static constexpr uint32 BATTLEGROUND_QUEUE_1v1 = 11;", "// 1v1 Arena constants are now defined in AZTH.h`nusing namespace AzthArenaConstants;"
                Set-Content -Path $azthScCpp -Value $scContent -NoNewline
                $fixed = $true
            }
        }
        
        if ($fixed) {
            Write-Host "  [AI] Fixed BATTLEGROUND_QUEUE_1v1 redefinition errors!" -ForegroundColor Green
            $script:errorsFixed++
        }
    }
    
    # Process other redefinition errors (C2374, C2086)
    foreach ($error in $errors) {
        $errorCode = $error.Code
        $errorMsg = $error.Message
        
        if ($errorCode -eq "2374" -or $errorCode -eq "2086") {
            if ($errorMsg -match "redefinition") {
                Write-Host "  [AI] Detected redefinition error (C$errorCode): $errorMsg" -ForegroundColor Yellow
                
                # Extract symbol name
                if ($errorMsg -match "'([^']+)':\s*redefinition") {
                    $symbol = $matches[1]
                    Write-Host "    [AI] Symbol: $symbol" -ForegroundColor Cyan
                    
                    # Extract file path from error message if available
                    if ($errorMsg -match "\(([^)]+)\):\s*error") {
                        $errorFilePath = $matches[1]
                        if (-not [System.IO.Path]::IsPathRooted($errorFilePath)) {
                            $errorFilePath = Join-Path $WorkspaceRoot $errorFilePath
                        }
                        
                        if (Test-Path $errorFilePath) {
                            # Try to fix by making it static or moving to header
                            $fileContent = Get-Content $errorFilePath -Raw
                            if ($fileContent -match "const\s+\w+\s+$symbol\s*=" -and $fileContent -notmatch "static\s+const") {
                                $fileContent = $fileContent -replace "const\s+(\w+)\s+$symbol\s*=", "static const `$1 $symbol ="
                                Set-Content -Path $errorFilePath -Value $fileContent -NoNewline
                                Write-Host "    [AI] Fixed: Made $symbol static" -ForegroundColor Green
                                $fixed = $true
                                $script:errorsFixed++
                            }
                        }
                    }
                }
            }
        }
    }
    
    return @{
        Fixed = $fixed
        ErrorsFound = $errorsFound
    }
}

# Function to check and process AI_FIX_REQUEST files (called from main loop when monitoring is enabled)
function Process-AIFixRequests {
    param(
        [string]$WorkspaceRoot = $PSScriptRoot,
        [int]$CheckInterval = 30
    )
    
    $now = Get-Date
    
    # Only check if enough time has passed
    if ($script:lastAIFixCheckTime -and (($now - $script:lastAIFixCheckTime).TotalSeconds -lt $CheckInterval)) {
        return $false
    }
    
    $script:lastAIFixCheckTime = $now
    $anyFixed = $false
    
    # Find all AI_FIX_REQUEST files
    $requestFiles = Get-ChildItem -Path $WorkspaceRoot -Filter "AI_FIX_REQUEST_*.txt" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if ($requestFiles) {
        Write-Host "  [AI] Checking $($requestFiles.Count) AI_FIX_REQUEST file(s)..." -ForegroundColor Cyan
        
        foreach ($file in $requestFiles) {
            $fileKey = "$($file.Name)|$($file.LastWriteTime.Ticks)"
            
            # Check if this is a new or modified file
            if (-not $script:processedAIFixFiles.ContainsKey($fileKey)) {
                Write-Host "  [AI] Processing: $($file.Name)" -ForegroundColor Yellow
                
                $result = Process-AIFixRequestFile -FilePath $file.FullName -WorkspaceRoot $WorkspaceRoot
                
                if ($result.Fixed) {
                    $anyFixed = $true
                    Write-Host "  [AI] Successfully fixed errors in $($file.Name)" -ForegroundColor Green
                }
                
                # Mark as processed
                $script:processedAIFixFiles[$fileKey] = @{
                    Processed = $true
                    Timestamp = Get-Date
                    Fixed = $result.Fixed
                }
            }
        }
    }
    
    return $anyFixed
}

# Main loop - runs continuously
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Starting CONTINUOUS improvement loop" -ForegroundColor Green
Write-Host "Loop will run indefinitely until stopped (Ctrl+C)" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

while ($runContinuously) {
    $iteration++
    $elapsed = (Get-Date) - $startTime
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    $elapsedHours = [int][math]::Floor($elapsed.TotalHours)
    $elapsedMins = [int]$elapsed.Minutes
    $elapsedSecs = [int]$elapsed.Seconds
    $elapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f $elapsedHours, $elapsedMins, $elapsedSecs
    Write-Host "Iteration: $iteration | Elapsed: $elapsedStr" -ForegroundColor Magenta
    Write-Host "Features Added: $featuresAdded | Files Modernized: $filesModernized | Errors Fixed: $errorsFixed" -ForegroundColor Magenta
    Write-Host "AI Requests Generated: $aiRequestsGenerated" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    # Check for AI request files first
    $hasAIRequest = Check-ForAIRequests
    if ($hasAIRequest) {
        Write-Host "  [AI] AI request files detected - ready for AI processing!" -ForegroundColor Yellow
        Write-Host "  [AI] The AI can now read and process these files automatically" -ForegroundColor Cyan
    }
    
    # Process AI_FIX_REQUEST files if monitoring is enabled
    if ($MonitorAIFixRequests) {
        $fixResult = Process-AIFixRequests -WorkspaceRoot $PSScriptRoot -CheckInterval $AIFixCheckInterval
        if ($fixResult) {
            Write-Host "  [AI] Auto-fixed errors from AI_FIX_REQUEST files!" -ForegroundColor Green
            Write-Host "  [AI] Rebuilding to verify fixes..." -ForegroundColor Yellow
        }
    }
    
    # Build the project
    $buildResult = Build-Project -Target "all"
    
    if ($buildResult.ExitCode -eq 0 -and $buildResult.ErrorCount -eq 0) {
        $consecutiveSuccessCount++
        Write-Host "`n[OK] Build successful! (Consecutive: $consecutiveSuccessCount)" -ForegroundColor Green
        Write-Host "  Warnings: $($buildResult.WarningCount)" -ForegroundColor Yellow
        
        if ($consecutiveSuccessCount -ge 2) {
            # Modernize code
            Write-Host "`n[->] Modernizing code..." -ForegroundColor Yellow
            Modernize-Code -MaxFiles 10
            
            # Improve existing features
            Write-Host "`n[->] Improving existing features..." -ForegroundColor Yellow
            Improve-ExistingFeatures
            
            # Add new feature every 3 successful builds
            if ($consecutiveSuccessCount % 3 -eq 0) {
                Write-Host "`n[->] Adding new WoW backport feature..." -ForegroundColor Cyan
                Add-WoWBackportFeature
            }
            
            Start-Sleep -Seconds 5
        }
    }
    else {
        $consecutiveSuccessCount = 0
        Write-Host "`n[FAIL] Build failed with $($buildResult.ErrorCount) errors" -ForegroundColor Red
        
        $errors = Extract-Errors -BuildOutput $buildResult.Output
        if ($errors.Count -gt 0) {
            Write-Host "`nTop errors:" -ForegroundColor Red
            $errors | Select-Object -First 10 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Red
            }
            
            # Try to automatically fix common errors
            Write-Host "`n[->] Attempting to fix errors automatically..." -ForegroundColor Yellow
            $fixed = Fix-CommonErrors -Errors $errors
            if ($fixed -gt 0) {
                $script:errorsFixed += $fixed
                Write-Host "  Fixed $fixed error(s)!" -ForegroundColor Green
            }
            
            # If there are unfixable errors, automatically request AI assistance
            if (Test-Path "unfixable_errors.log") {
                $logSize = (Get-Item "unfixable_errors.log").Length
                if ($logSize -gt 0) {
                    Write-Host "`n[!] Unfixable errors detected!" -ForegroundColor Yellow
                    
                    # Automatically generate AI request
                    Request-AIAssistance -Errors $errors -BuildOutput $buildResult.Output
                }
            }
        }
        
        # Wait a bit before retrying
        Start-Sleep -Seconds 10
    }
    
    # Loop runs continuously - no time limit
    Write-Host "`nWaiting 30 seconds before next iteration..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the loop`n" -ForegroundColor Gray
    
    # Use try-catch to ensure loop continues even if sleep fails
    # Also add error handling to prevent loop from stopping
    try {
        Start-Sleep -Seconds 30
    }
    catch {
        Write-Host "Sleep interrupted, continuing..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
    
    # Ensure we don't exit on errors - continue the loop
    if ($Error.Count -gt 100) {
        $Error.Clear()
        Write-Host "Cleared error buffer to prevent memory issues" -ForegroundColor Gray
    }
}

# Final summary - this should only be reached if loop completes normally
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Loop completed normally!" -ForegroundColor Green
Write-Host "Total iterations: $iteration" -ForegroundColor Green
Write-Host "Features added: $featuresAdded" -ForegroundColor Green
Write-Host "Files modernized: $filesModernized" -ForegroundColor Green
Write-Host "Errors fixed: $errorsFixed" -ForegroundColor Green
Write-Host "AI requests generated: $aiRequestsGenerated" -ForegroundColor Cyan
$totalElapsed = (Get-Date) - $startTime
$totalHours = [int][math]::Floor($totalElapsed.TotalHours)
$totalMins = [int]$totalElapsed.Minutes
$totalSecs = [int]$totalElapsed.Seconds
$totalElapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f $totalHours, $totalMins, $totalSecs
Write-Host "Total elapsed time: $totalElapsedStr" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta

# Keep window open for 60 seconds so user can see final results
Write-Host "`nWindow will close in 60 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

$totalElapsed = (Get-Date) - $startTime
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Loop completed!" -ForegroundColor Green
Write-Host "Total iterations: $iteration" -ForegroundColor Green
Write-Host "Features added: $featuresAdded" -ForegroundColor Green
Write-Host "Files modernized: $filesModernized" -ForegroundColor Green
Write-Host "Errors fixed: $errorsFixed" -ForegroundColor Green
Write-Host "AI requests generated: $aiRequestsGenerated" -ForegroundColor Cyan
$totalHours = [int][math]::Floor($totalElapsed.TotalHours)
$totalMins = [int]$totalElapsed.Minutes
$totalSecs = [int]$totalElapsed.Seconds
$totalElapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f $totalHours, $totalMins, $totalSecs
Write-Host "Total elapsed time: $totalElapsedStr" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
