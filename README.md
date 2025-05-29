# SleepManager

A PowerShell module for managing computer sleep and display power states using the Windows API. This module provides reliable functions to prevent system sleep during critical operations and automatically restore normal power management behavior.

## Description

SleepManager allows you to programmatically control Windows sleep behavior from PowerShell. Whether you need to prevent sleep during long-running scripts, presentations, or file transfers, this module provides a clean and safe way to manage power states with automatic cleanup.

**Key Features:**
- Disable/enable system sleep mode
- Optional display sleep prevention
- Automatic cleanup when PowerShell exits
- Exception-safe script block execution
- Process-scoped sleep prevention (no system-wide changes)
- **NEW in v1.1.0:** Custom logger support with RunLogger integration

## Getting Started

### Prerequisites
- Windows PowerShell 5.1 or later
- .NET Framework 4.5.2 or later
- Windows operating system (uses Windows API)
- RunLog module (v2.0.0 or later) - automatically imported

### Installation

**From PowerShell Gallery (Recommended):**
```powershell
# Install for current user
Install-Module -Name SleepManager -Scope CurrentUser

# Install for all users (requires admin)
Install-Module -Name SleepManager -Scope AllUsers

# Import the module
Import-Module SleepManager
```

**Manual Installation:**
1. **Download the module files** to a folder named `SleepManager`
2. **Ensure RunLog module is available** (required dependency)
3. **Copy to PowerShell modules directory:**
   ```powershell
   # For current user only
   Copy-Item -Path ".\SleepManager" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse
   
   # For all users (requires admin)
   Copy-Item -Path ".\SleepManager" -Destination "$env:ProgramFiles\WindowsPowerShell\Modules\" -Recurse
   ```

4. **Import the module:**
   ```powershell
   Import-Module SleepManager
   ```

**Note:** Installing from PowerShell Gallery automatically handles the RunLog module dependency.

### Quick Start Examples

**Prevent sleep during a long-running operation:**
```powershell
Invoke-WithoutSleep {
    # Your long-running code here
    Start-Process "backup-script.exe" -Wait
    Copy-Item "large-file.zip" "\\server\backup\" -Force
}
```

**Prevent both sleep and display timeout (great for presentations):**
```powershell
Invoke-WithoutSleep -KeepDisplayOn {
    Write-Host "Display will stay on during this block"
    Start-Sleep 300  # 5 minutes
}
```

**Manual sleep control:**
```powershell
# Disable sleep
Disable-ComputerSleep

# Your work here...

# Re-enable sleep
Enable-ComputerSleep
```

**Use custom logging (NEW in v1.1.0):**
```powershell
# Create your own logger with custom settings
$myLogger = New-RunLogger -LogFilePath "C:\Logs\MyApp.log" -MinimumLogLevel Debug
Set-SleepManagerLogger -Logger $myLogger

# Now all SleepManager operations will use your logger
Disable-ComputerSleep
```

## Functions

### `Disable-ComputerSleep`
Prevents the computer from going to sleep.

**Parameters:**
- `-KeepDisplayOn` (optional): Also prevents the display from turning off

**Returns:** Boolean indicating success/failure

**Example:**
```powershell
# Prevent system sleep only
Disable-ComputerSleep

# Prevent both system sleep and display timeout
Disable-ComputerSleep -KeepDisplayOn
```

### `Enable-ComputerSleep`
Re-enables normal computer sleep behavior.

**Returns:** Boolean indicating success/failure

**Example:**
```powershell
Enable-ComputerSleep
```

### `Invoke-WithoutSleep`
Executes a script block with sleep disabled, guaranteeing cleanup even if exceptions occur.

**Parameters:**
- `ScriptBlock` (required): The code to execute with sleep disabled
- `-KeepDisplayOn` (optional): Also prevents display timeout

**Example:**
```powershell
Invoke-WithoutSleep -KeepDisplayOn {
    # Critical operation that shouldn't be interrupted
    & ".\critical-backup.ps1"
    
    # Even if an exception occurs above, sleep will be re-enabled
}
```

### `Set-SleepManagerLogger` (NEW in v1.1.0)
Sets a custom RunLogger instance for the SleepManager module.

**Parameters:**
- `-Logger` (required): An existing RunLogger instance

**Example:**
```powershell
# Create your own logger with custom settings
$myLogger = New-RunLogger -LogFilePath "C:\Logs\MyApp.log" -MinimumLogLevel Debug
Set-SleepManagerLogger -Logger $myLogger

# Use the same logger across multiple modules for unified logging
$sharedLogger = New-RunLogger -LogFilePath "C:\Logs\SharedApp.log"
Set-SleepManagerLogger -Logger $sharedLogger
```

### `Get-SleepManagerLogger` (NEW in v1.1.0)
Gets the current RunLogger instance used by SleepManager.

**Returns:** The current RunLogger instance

**Example:**
```powershell
$currentLogger = Get-SleepManagerLogger
$currentLogger.Information("This message will appear in the SleepManager log")
```

## Safety Features

- **Automatic Cleanup**: Sleep is automatically restored when PowerShell exits
- **Exception Safety**: `Invoke-WithoutSleep` always restores sleep state, even if your code throws exceptions
- **Process Scoped**: Changes only affect the current PowerShell process, not system-wide settings
- **Multiple Safety Nets**: Registers multiple cleanup events to ensure reliable restoration
- **Comprehensive Logging**: All operations are logged with configurable detail levels

## Logging (NEW in v1.1.0)

SleepManager now includes comprehensive logging capabilities:

- **Default Logging**: Automatically logs to `$env:TEMP\SleepManager.log` with Information level
- **Custom Loggers**: Use your own RunLogger instance for integration with existing logging infrastructure
- **Flexible Configuration**: Control log file location, minimum log levels, and output format
- **Shared Logging**: Use the same logger across multiple modules for unified log management

**Logging Levels:**
- `Debug`: Detailed diagnostic information
- `Information`: General operational messages (default)
- `Warning`: Warning conditions that don't prevent operation
- `Error`: Error conditions
- `Critical`: Critical failures

## Use Cases

- **Long-running scripts**: Prevent interruption during backups, file transfers, or data processing
- **Presentations**: Keep display active during demos or presentations
- **Media playback**: Prevent sleep during video or audio playback
- **Remote operations**: Ensure remote sessions stay active
- **Automated tasks**: Prevent scheduled tasks from being interrupted by sleep
- **Enterprise applications**: Integrate with existing logging infrastructure

## Help

### Common Issues

**Q: Sleep prevention isn't working**
- Ensure you're running on Windows with appropriate permissions
- Check that the function returns `$true` indicating success
- Some enterprise policies may override power management settings
- Check the log files for detailed error information

**Q: Display still turns off with `-KeepDisplayOn`**
- Verify the function returned `$true`
- Check Windows display settings for very short timeout values
- Some display drivers may have independent timeout settings

**Q: Computer goes to sleep after PowerShell exits**
- This is expected behavior - sleep prevention is automatically cleared
- Use `Disable-ComputerSleep` in a persistent PowerShell session if needed

**Q: How do I check what's being logged?**
- Use `Get-SleepManagerLogger` to get the current logger instance
- Check the log file path: `(Get-SleepManagerLogger).LogFilePath`
- View recent log entries: `Get-Content (Get-SleepManagerLogger).LogFilePath -Tail 10`

### Getting Function Help
```powershell
Get-Help Disable-ComputerSleep -Full
Get-Help Enable-ComputerSleep -Full
Get-Help Invoke-WithoutSleep -Full
Get-Help Set-SleepManagerLogger -Full
Get-Help Get-SleepManagerLogger -Full
```

## Authors

**aaturpin** - Initial development and module design

## Version History

- **1.1.0** - Logger Integration Release
  - Added support for custom RunLogger instances
  - New functions: `Set-SleepManagerLogger` and `Get-SleepManagerLogger`
  - Enhanced logging throughout all operations
  - Improved error handling and diagnostics
  - Added RunLog module dependency

- **1.0** - Initial release
  - Core sleep management functionality
  - Windows API integration
  - Automatic cleanup mechanisms
  - Comprehensive error handling

## License

Copyright (c) 2025. All rights reserved.

## Acknowledgments

- Built using SAPIEN Technologies PowerShell Studio 2025
- Utilizes Windows `SetThreadExecutionState` API for reliable power management
- Integrates with RunLog module for comprehensive logging capabilities
- Inspired by the need for robust sleep prevention in automation scenarios