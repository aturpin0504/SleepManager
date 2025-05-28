<#	
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
	
	try
	{
		$flags = [SleepControl]::ES_CONTINUOUS -bor [SleepControl]::ES_SYSTEM_REQUIRED
		
		if ($KeepDisplayOn)
		{
			$flags = $flags -bor [SleepControl]::ES_DISPLAY_REQUIRED
		}
		
		$result = [SleepControl]::SetThreadExecutionState($flags)
		
		if ($result -eq 0)
		{
			Write-Warning "Failed to disable sleep mode"
			return $false
		}
		
		return $true
	}
	catch
	{
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
	
	try
	{
		# Clear all execution state flags by setting only ES_CONTINUOUS
		$result = [SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS)
		
		if ($result -eq 0)
		{
			Write-Warning "Failed to restore sleep mode"
			return $false
		}
		
		return $true
	}
	catch
	{
		Write-Error "Failed to enable computer sleep: $($_.Exception.Message)"
		return $false
	}
}

# Register multiple cleanup events to restore sleep when PowerShell exits
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
	[SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS) | Out-Null
} -SupportEvent

# Also register for process exit (additional safety net)
try
{
	$null = Register-ObjectEvent -InputObject ([System.AppDomain]::CurrentDomain) -EventName ProcessExit -Action {
		[SleepControl]::SetThreadExecutionState([SleepControl]::ES_CONTINUOUS) | Out-Null
	} -SupportEvent
}
catch
{
	# ProcessExit event registration might fail in some environments, continue silently
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
	
	try
	{
		$disableResult = Disable-ComputerSleep -KeepDisplayOn:$KeepDisplayOn
		if (-not $disableResult)
		{
			Write-Warning "Failed to disable sleep, continuing anyway..."
		}
		
		# Execute the user's script block
		& $ScriptBlock
	}
	finally
	{
		# This ALWAYS runs, even if ScriptBlock throws an exception
		$null = Enable-ComputerSleep
	}
}

# Export functions
Export-ModuleMember -Function Disable-ComputerSleep, Enable-ComputerSleep, Invoke-WithoutSleep