# SleepManager

A robust PowerShell module for managing computer sleep and display power states using the Windows API. This module provides reliable functions to prevent system sleep during critical operations with comprehensive logging and automatic cleanup mechanisms.

## Overview

SleepManager allows you to programmatically control Windows sleep behavior from PowerShell with enterprise-grade reliability. Whether you need to prevent sleep during long-running scripts, presentations, file transfers, or automated tasks, this module provides a clean and safe way to manage power states with built-in logging and automatic restoration.

**Key Features:**
- 🛡️ **Process-scoped sleep prevention** (no system-wide changes)
- 🖥️ **Optional display sleep prevention** for presentations and media
- 🔄 **Automatic cleanup** with multiple safety nets
- 📝 **Comprehensive logging** via integrated RunLog module
- ⚡ **Exception-safe execution** with guaranteed state restoration
- 🔧 **Multiple cleanup mechanisms** (PowerShell exit, process exit, module unload)
- ✅ **Extensive test suite** with Pester integration

## Requirements

- **Operating System:** Windows (uses Windows SetThreadExecutionState API)
- **PowerShell:** Version 5.1 or later
- **Framework:** .NET Framework 4.5.2 or later
- **Dependencies:** RunLog module (v2.0.0+) - included with SleepManager

## Installation

### Option 1: PowerShell Gallery (Recommended)

Install directly from the PowerShell Gallery:

```powershell
# Install for current user
Install-Module -Name SleepManager -Scope CurrentUser

# Install for all users (requires administrator privileges)
Install-Module -Name SleepManager -Scope AllUsers

# Import the module
Import-Module SleepManager
```

### Option 2: Manual Installation

1. **Download or clone** the SleepManager module files
2. **Copy to PowerShell modules directory:**

   ```powershell
   # For current user only
   $userModulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\SleepManager"
   Copy-Item -Path ".\SleepManager" -Destination $userModulesPath -Recurse -Force
   
   # For all users (requires administrator privileges)
   $systemModulesPath = "$env:ProgramFiles\WindowsPowerShell\Modules\SleepManager"
   Copy-Item -Path ".\SleepManager" -Destination $systemModulesPath -Recurse -Force
   ```

3. **Import the module:**
   ```powershell
   Import-Module SleepManager -Force
   ```

### Verify Installation

Test your installation by running the included test script:
```powershell
# Navigate to the module directory and run tests
.\Test-Module.ps1
```

## Quick Start

### Basic Usage Examples

**Prevent sleep during a critical operation:**
```powershell
Invoke-WithoutSleep {
    # Critical backup operation
    Start-Process "backup-utility.exe" -ArgumentList "--full-backup" -Wait
    Write-Host "Backup completed successfully"
}
# Sleep is automatically restored here, even if backup fails
```

**Presentation mode (prevent sleep + display timeout):**
```powershell
Invoke-WithoutSleep -KeepDisplayOn {
    Write-Host "Starting presentation - display will stay active"
    Start-Process "PowerPoint.exe" -ArgumentList "presentation.pptx" -Wait
}
```

**Manual sleep control for extended operations:**
```powershell
# Disable sleep for manual control
$result = Disable-ComputerSleep -KeepDisplayOn
if ($result) {
    Write-Host "Sleep disabled successfully"
    
    # Your long-running operations here
    1..100 | ForEach-Object {
        Start-Job -ScriptBlock { 
            # Some parallel work
            Start-Sleep 10 
        }
    }
    Get-Job | Wait-Job | Remove-Job
    
    # Always re-enable when done
    Enable-ComputerSleep
}
```

## Function Reference

### `Disable-ComputerSleep`

Prevents the computer from entering sleep mode using the Windows SetThreadExecutionState API.

**Syntax:**
```powershell
Disable-ComputerSleep [-KeepDisplayOn]
```

**Parameters:**
- `-KeepDisplayOn` (Switch): Also prevents display from turning off

**Returns:** 
- `$true` if sleep was disabled successfully
- `$false` if the operation failed

**Examples:**
```powershell
# Prevent system sleep only
Disable-ComputerSleep

# Prevent both system sleep and display timeout
Disable-ComputerSleep -KeepDisplayOn

# Check if operation succeeded
$success = Disable-ComputerSleep
if (-not $success) {
    Write-Warning "Could not disable sleep - check permissions"
}
```

### `Enable-ComputerSleep`

Restores normal computer sleep and display timeout behavior.

**Syntax:**
```powershell
Enable-ComputerSleep
```

**Returns:** 
- `$true` if sleep was re-enabled successfully
- `$false` if the operation failed

**Examples:**
```powershell
# Restore normal sleep behavior
Enable-ComputerSleep

# Verify restoration
if (Enable-ComputerSleep) {
    Write-Host "Sleep mode restored successfully"
}
```

### `Invoke-WithoutSleep`

Executes a script block with sleep disabled, providing guaranteed cleanup even if exceptions occur.

**Syntax:**
```powershell
Invoke-WithoutSleep [-KeepDisplayOn] -ScriptBlock <ScriptBlock>
```

**Parameters:**
- `ScriptBlock` (Required): The code to execute with sleep disabled
- `-KeepDisplayOn` (Switch): Also prevents display timeout during execution

**Examples:**
```powershell
# Basic usage with exception safety
Invoke-WithoutSleep {
    try {
        # Risky operation that might fail
        Invoke-RestMethod "https://api.unreliable-service.com/data" -TimeoutSec 3600
    }
    catch {
        Write-Error "API call failed: $_"
        throw  # Re-throw to calling script
    }
}
# Sleep is restored regardless of success or failure

# File transfer with display prevention
Invoke-WithoutSleep -KeepDisplayOn {
    $source = "\\server\large-dataset\"
    $destination = "C:\LocalData\"
    
    Write-Progress -Activity "Copying files" -Status "Starting transfer"
    robocopy $source $destination /E /MT:8 /R:3 /W:10
    Write-Progress -Activity "Copying files" -Completed
}
```

## Advanced Features

### Comprehensive Logging

SleepManager includes detailed logging via the integrated RunLog module:

```powershell
# Log file location
$logPath = "$env:TEMP\SleepManager.log"

# View recent log entries
Get-Content $logPath -Tail 20

# Monitor log in real-time
Get-Content $logPath -Wait -Tail 10
```

**Log Entry Format:**
```
[2025-05-28 14:30:15.123] [1234:5678] [Information] Successfully disabled computer sleep mode
[2025-05-28 14:30:45.456] [1234:5678] [Information] Invoke-WithoutSleep completed successfully - sleep mode restored
```

### Multiple Safety Mechanisms

The module implements several layers of automatic cleanup:

1. **PowerShell.Exiting Event**: Restores sleep when PowerShell closes
2. **ProcessExit Event**: Additional safety net for process termination  
3. **Module OnRemove**: Cleanup when module is unloaded
4. **Try/Finally Blocks**: Exception-safe restoration in `Invoke-WithoutSleep`

### Thread and Process Safety

- Uses Windows API mutexes for safe concurrent logging
- Process-scoped sleep prevention (doesn't affect other applications)
- Thread-safe execution state management

## Use Cases & Scenarios

### 🔄 **Automated Operations**
```powershell
# Scheduled task that shouldn't be interrupted
Invoke-WithoutSleep {
    # Database backup
    sqlcmd -S localhost -E -Q "BACKUP DATABASE MyDB TO DISK='C:\Backups\MyDB.bak'"
    
    # File cleanup
    Get-ChildItem "C:\Temp" -Recurse | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force
    
    # Send completion email
    Send-MailMessage -To "admin@company.com" -Subject "Backup Complete" -Body "Database backup finished successfully"
}
```

### 🎥 **Media and Presentations**
```powershell
# Video processing that takes hours
Invoke-WithoutSleep -KeepDisplayOn {
    ffmpeg -i "input-video.mov" -c:v libx264 -crf 18 -preset slow "output-video.mp4"
    Write-Host "Video encoding completed"
}
```

### 🌐 **Remote Operations**
```powershell
# Keep session alive during remote work
Disable-ComputerSleep
try {
    # Connect to remote systems
    $sessions = @()
    $servers = @("server01", "server02", "server03")
    
    foreach ($server in $servers) {
        $sessions += New-PSSession -ComputerName $server
    }
    
    # Perform remote operations
    Invoke-Command -Session $sessions -ScriptBlock {
        # Long-running remote task
        Get-WmiObject -Class Win32_LogicalDisk | Export-Csv "C:\Reports\DiskInfo_$(Get-Date -Format 'yyyyMMdd').csv"
    }
}
finally {
    # Cleanup sessions and restore sleep
    Get-PSSession | Remove-PSSession
    Enable-ComputerSleep
}
```

### 📊 **Data Processing**
```powershell
# Large dataset processing
Invoke-WithoutSleep {
    $csvFiles = Get-ChildItem "C:\DataImport\*.csv"
    $totalFiles = $csvFiles.Count
    $processed = 0
    
    foreach ($file in $csvFiles) {
        $progress = [math]::Round(($processed / $totalFiles) * 100, 1)
        Write-Progress -Activity "Processing CSV files" -Status "$progress% Complete" -PercentComplete $progress
        
        # Process each file (could take hours for large datasets)
        Import-Csv $file.FullName | 
            Where-Object { $_.Status -eq "Active" } |
            Export-Csv "C:\ProcessedData\$($file.BaseName)_filtered.csv" -NoTypeInformation
        
        $processed++
    }
    Write-Progress -Activity "Processing CSV files" -Completed
}
```

## Testing and Validation

### Run Built-in Tests

The module includes comprehensive Pester tests:

```powershell
# Run all tests
.\Test-Module.ps1

# Run specific test categories
Invoke-Pester -Path ".\Tests\" -Tag "BasicFunctionality"
Invoke-Pester -Path ".\Tests\" -Tag "ErrorHandling"
```

### Manual Testing Scenarios

1. **Sleep Prevention Test:**
   ```powershell
   Disable-ComputerSleep
   # Leave computer idle for 10+ minutes
   # Verify system doesn't sleep
   Enable-ComputerSleep
   ```

2. **Display Prevention Test:**
   ```powershell
   Disable-ComputerSleep -KeepDisplayOn
   # Leave computer idle past normal display timeout
   # Verify display stays active
   Enable-ComputerSleep
   ```

3. **Exception Safety Test:**
   ```powershell
   Invoke-WithoutSleep {
       Write-Host "Sleep disabled"
       throw "Test exception"  # This should still restore sleep
   }
   # Verify sleep is restored despite exception
   ```

## Troubleshooting

### Common Issues

**❌ Function returns `$false` or sleep prevention doesn't work:**
- **Cause:** Insufficient permissions or enterprise policy restrictions
- **Solution:** Run PowerShell as Administrator, check Group Policy settings for power management

**❌ Display still turns off with `-KeepDisplayOn`:**
- **Cause:** Very aggressive display timeout settings or driver issues
- **Solution:** Check Windows display settings, update display drivers, verify function returns `$true`

**❌ Computer sleeps after PowerShell exits:**
- **Cause:** This is normal and expected behavior
- **Solution:** Sleep prevention is process-scoped and automatically clears on exit

**❌ Logging errors or permission issues:**
- **Cause:** Restricted access to temp directory
- **Solution:** Ensure write access to `$env:TEMP` or modify log path in module

### Debug Mode

Enable debug logging for troubleshooting:

```powershell
# Import module with debug logging
Remove-Module SleepManager -Force -ErrorAction SilentlyContinue
Import-Module SleepManager -Force

# Check debug logs
$logPath = "$env:TEMP\SleepManager.log"
Get-Content $logPath | Where-Object { $_ -match "\[Debug\]" }
```

### Getting Help

```powershell
# Detailed help for each function
Get-Help Disable-ComputerSleep -Full
Get-Help Enable-ComputerSleep -Full  
Get-Help Invoke-WithoutSleep -Full -Examples

# View module information
Get-Module SleepManager -ListAvailable
```

## Module Information

- **Version:** 1.0.0
- **Author:** aaturpin
- **Created:** May 27, 2025
- **Built with:** SAPIEN Technologies PowerShell Studio 2025 v5.9.256
- **Dependencies:** RunLog v2.0.0 (included)
- **License:** Copyright (c) 2025. All rights reserved.

## Architecture Notes

- **Windows API Integration:** Uses `SetThreadExecutionState` from kernel32.dll
- **Type System:** Custom `SleepControl` class with P/Invoke declarations
- **Logging:** Thread-safe logging with mutex-based file access and retry logic
- **Event Handling:** Multiple registered cleanup events for reliability
- **Error Handling:** Comprehensive exception handling with graceful degradation

## Contributing

When contributing to SleepManager:

1. **Test thoroughly** on different Windows versions
2. **Maintain backward compatibility** with PowerShell 5.1
3. **Follow existing logging patterns** for consistency
4. **Add appropriate Pester tests** for new functionality
5. **Update documentation** for any new features or parameters

## Acknowledgments

- Built using **SAPIEN Technologies PowerShell Studio 2025**
- Utilizes Windows **SetThreadExecutionState API** for reliable power management
- **RunLog integration** provides enterprise-grade logging capabilities
- Inspired by the need for robust sleep prevention in automation and enterprise scenarios