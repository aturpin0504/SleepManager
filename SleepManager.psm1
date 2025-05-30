﻿<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.256
	 Created on:   	5/27/2025 8:51 PM
	 Created by:   	aaturpin
	 Organization: 	
	 Filename:     	SleepManager.psm1
	-------------------------------------------------------------------------
	 Module Name: SleepManager
	===========================================================================
#>

# Import required modules
Import-Module RunLog -Force

# Module-level logger variable
$script:Logger = $null
$script:LoggerIsOwned = $false

# Initialize module logger (default behavior if no logger is provided)
function Initialize-DefaultLogger
{
	if (-not $script:Logger)
	{
		$script:Logger = New-RunLogger -LogFilePath "$env:TEMP\SleepManager.log" -MinimumLogLevel Information
		$script:LoggerIsOwned = $true
	}
}

# Function to set an external logger
function Set-SleepManagerLogger
{
    <#
    .SYNOPSIS
        Sets a custom RunLogger instance for the SleepManager module.
    
    .DESCRIPTION
        Allows you to provide your own RunLogger instance for the SleepManager module
        to use instead of creating its own default logger. This enables integration
        with existing logging infrastructure and custom log configurations.
    
    .PARAMETER Logger
        An existing RunLogger instance to use for logging.
    
    .EXAMPLE
        # Create your own logger with custom settings
        $myLogger = New-RunLogger -LogFilePath "C:\Logs\MyApp.log" -MinimumLogLevel Debug
        Set-SleepManagerLogger -Logger $myLogger
        
        # Now all SleepManager operations will use your logger
        Disable-ComputerSleep
    
    .EXAMPLE
        # Use the same logger across multiple modules
        $sharedLogger = New-RunLogger -LogFilePath "C:\Logs\SharedApp.log"
        Set-SleepManagerLogger -Logger $sharedLogger
        # Other modules could also use $sharedLogger for unified logging
    #>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		$Logger
	)
	
	# Validate that the provided object is actually a RunLogger instance
	if ($Logger.GetType().Name -ne 'RunLogger')
	{
		throw "Logger parameter must be a RunLogger instance. Use New-RunLogger to create one."
	}
	
	$script:Logger = $Logger
	$script:LoggerIsOwned = $false
	
	$script:Logger.Information("External logger configured for SleepManager module")
}

# Function to get the current logger (useful for debugging or sharing)
function Get-SleepManagerLogger
{
    <#
    .SYNOPSIS
        Gets the current RunLogger instance used by SleepManager.
    
    .DESCRIPTION
        Returns the RunLogger instance currently being used by the SleepManager module.
        This can be useful for debugging or for sharing the same logger with other components.
    
    .EXAMPLE
        $currentLogger = Get-SleepManagerLogger
        $currentLogger.Information("This message will appear in the SleepManager log")
    #>
	
	[CmdletBinding()]
	param ()
	
	if (-not $script:Logger)
	{
		Initialize-DefaultLogger
	}
	
	return $script:Logger
}

# Initialize default logger if none is set
Initialize-DefaultLogger

# Define the Windows API type for sleep control
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class SleepControl {
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
    
    // Constants for SetThreadExecutionState
    public const uint ES_CONTINUOUS = 0x80000000;
    public const uint ES_SYSTEM_REQUIRED = 0x00000001;
    public const uint ES_DISPLAY_REQUIRED = 0x00000002;
}
"@

$script:Logger.Information("SleepManager module loaded successfully")

function Disable-ComputerSleep
{
    <#
    .SYNOPSIS
        Prevents the computer from going to sleep.
    
    .DESCRIPTION
        Uses Windows SetThreadExecutionState API to prevent the system from entering 
        sleep mode. This is process-scoped and will automatically be cleared when 
        PowerShell exits. Also sets up try/finally and trap handlers for additional protection.
    
    .PARAMETER KeepDisplayOn
        If specified, also prevents the display from turning off.
    
    .EXAMPLE
        Disable-ComputerSleep
        Prevents system sleep but allows display to turn off.
    
    .EXAMPLE
        Disable-ComputerSleep -KeepDisplayOn
        Prevents both system sleep and display from turning off.
    #>
	
	[CmdletBinding()]
	param (
		[switch]$KeepDisplayOn
	)
	
	# Ensure logger is initialized
	if (-not $script:Logger)
	{
		Initialize-DefaultLogger
	}
	
	$script:Logger.Information("Attempting to disable computer sleep. KeepDisplayOn: $KeepDisplayOn")
	
	try
	{
		$flags = [SleepControl]::ES_CONTINUOUS -bor [SleepControl]::ES_SYSTEM_REQUIRED
		
		if ($KeepDisplayOn)
		{
			$flags = $flags -bor [SleepControl]::ES_DISPLAY_REQUIRED
			$script:Logger.Debug("Display sleep prevention enabled")
		}
		
		$script:Logger.Debug("Calling SetThreadExecutionState with flags: $flags")
		$result = [SleepControl]::SetThreadExecutionState($flags)
		
		if ($result -eq 0)
		{
			$script:Logger.Warning("SetThreadExecutionState returned 0 - failed to disable sleep mode")
			Write-Warning "Failed to disable sleep mode"
			return $false
		}
		
		$script:Logger.Information("Successfully disabled computer sleep mode")
		return $true
	}
	catch
	{
		$script:Logger.Error("Failed to disable computer sleep", $_.Exception)
		Write-Error "Failed to disable computer sleep: $($_.Exception.Message)"
		return $false
	}
}

function Enable-ComputerSleep
{
    <#
    .SYNOPSIS
        Re-enables computer sleep mode.
    
    .DESCRIPTION
        Clears the thread execution state to allow the system to return to normal
        power management behavior, including sleep and display timeout.
    
    .EXAMPLE
        Enable-ComputerSleep
        Restores normal sleep behavior.
    #>
	
	[CmdletBinding()]
	param ()
	
	# Ensure logger is initialized
	if (-not $script:Logger)
	{
		Initialize-DefaultLogger
	}
	
	$script:Logger.Information("Attempting to re-enable computer sleep")
	
	try
	{
		# Clear all execution state flags by setting only ES_CONTINUOUS
		$script:Logger.Debug("Calling SetThreadExecutionState to clear execution state")
		$result = [SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS)
		
		if ($result -eq 0)
		{
			$script:Logger.Warning("SetThreadExecutionState returned 0 - failed to restore sleep mode")
			Write-Warning "Failed to restore sleep mode"
			return $false
		}
		
		$script:Logger.Information("Successfully re-enabled computer sleep mode")
		return $true
	}
	catch
	{
		$script:Logger.Error("Failed to enable computer sleep", $_.Exception)
		Write-Error "Failed to enable computer sleep: $($_.Exception.Message)"
		return $false
	}
}

# Register multiple cleanup events to restore sleep when PowerShell exits
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
	try
	{
		[SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS) | Out-Null
		if ($script:Logger)
		{
			$script:Logger.Information("PowerShell exiting - sleep mode restored via cleanup event")
		}
	}
	catch
	{
		# Silent cleanup - don't throw exceptions during shutdown
	}
} -SupportEvent

# Also register for process exit (additional safety net)
try
{
	$null = Register-ObjectEvent -InputObject ([System.AppDomain]::CurrentDomain) -EventName ProcessExit -Action {
		try
		{
			[SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS) | Out-Null
			if ($script:Logger)
			{
				$script:Logger.Information("Process exiting - sleep mode restored via ProcessExit event")
			}
		}
		catch
		{
			# Silent cleanup - don't throw exceptions during shutdown
		}
	} -SupportEvent
	$script:Logger.Debug("ProcessExit event handler registered successfully")
}
catch
{
	$script:Logger.Warning("ProcessExit event registration failed - continuing without it", $_.Exception)
}

function Invoke-WithoutSleep
{
    <#
    .SYNOPSIS
        Executes a script block with sleep disabled, guaranteeing cleanup.
    
    .DESCRIPTION
        Disables sleep, executes the provided script block, and always re-enables 
        sleep afterward, even if the script block throws an exception.
    
    .PARAMETER ScriptBlock
        The script block to execute with sleep disabled.
    
    .PARAMETER KeepDisplayOn
        If specified, also prevents the display from turning off.
    
    .EXAMPLE
        Invoke-WithoutSleep { 
            Write-Host "Sleep is disabled during this block"
            Start-Sleep 30
        }
    
    .EXAMPLE
        Invoke-WithoutSleep -KeepDisplayOn { 
            # Long running process here
            & "some-long-process.exe"
        }
    #>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ScriptBlock]$ScriptBlock,
		[switch]$KeepDisplayOn
	)
	
	# Ensure logger is initialized
	if (-not $script:Logger)
	{
		Initialize-DefaultLogger
	}
	
	$script:Logger.Information("Starting Invoke-WithoutSleep execution. KeepDisplayOn: $KeepDisplayOn")
	
	try
	{
		$disableResult = Disable-ComputerSleep -KeepDisplayOn:$KeepDisplayOn
		if (-not $disableResult)
		{
			$script:Logger.Warning("Failed to disable sleep, continuing with script block execution anyway")
			Write-Warning "Failed to disable sleep, continuing anyway..."
		}
		
		$script:Logger.Debug("Executing user script block")
		# Execute the user's script block
		& $ScriptBlock
		$script:Logger.Debug("User script block execution completed")
	}
	catch
	{
		$script:Logger.Error("Exception occurred during script block execution", $_.Exception)
		throw
	}
	finally
	{
		# This ALWAYS runs, even if ScriptBlock throws an exception
		$script:Logger.Debug("Executing cleanup - re-enabling sleep")
		$enableResult = Enable-ComputerSleep
		if ($enableResult)
		{
			$script:Logger.Information("Invoke-WithoutSleep completed successfully - sleep mode restored")
		}
		else
		{
			$script:Logger.Warning("Invoke-WithoutSleep completed but failed to restore sleep mode")
		}
	}
}

# Module cleanup when unloaded
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	try
	{
		[SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS) | Out-Null
		if ($script:Logger)
		{
			$script:Logger.Information("SleepManager module unloaded - sleep mode restored")
		}
	}
	catch
	{
		# Silent cleanup
	}
}

# Export functions
Export-ModuleMember -Function Disable-ComputerSleep, Enable-ComputerSleep, Invoke-WithoutSleep, Set-SleepManagerLogger, Get-SleepManagerLogger