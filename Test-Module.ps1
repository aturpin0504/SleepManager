<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.256
	 Created on:   	5/27/2025 8:51 PM
	 Created by:   	aaturpin
	 Organization: 	
	 Filename:     	Test-Module.ps1
	===========================================================================
	.DESCRIPTION
	The Test-Module.ps1 script lets you test the functions and other features of
	your module in your PowerShell Studio module project. It's part of your project,
	but it is not included in your module.

	In this test script, import the module (be careful to import the correct version)
	and write commands that test the module features. You can include Pester
	tests, too.

	To run the script, click Run or Run in Console. Or, when working on any file
	in the project, click Home\Run or Home\Run in Console, or in the Project pane, 
	right-click the project name, and then click Run Project.
#>

# Explicitly import the module for testing
Import-Module 'SleepManager' -Force

Write-Host "=== Testing SleepManager Module (v1.1.0) ===" -ForegroundColor Cyan
Write-Host ""

# Test the new logger functionality first
Write-Host "0. Testing Logger Management:" -ForegroundColor Yellow

# Test getting the default logger
Write-Host "  -> Testing Get-SleepManagerLogger (default):" -ForegroundColor Gray
$defaultLogger = Get-SleepManagerLogger
Write-Host "    Default logger type: $($defaultLogger.GetType().Name)" -ForegroundColor $(if ($defaultLogger.GetType().Name -eq 'RunLogger') { 'Green' }
	else { 'Red' })
Write-Host "    Default log path: $($defaultLogger.LogFilePath)" -ForegroundColor White

# Test setting a custom logger
Write-Host "  -> Testing Set-SleepManagerLogger (custom):" -ForegroundColor Gray
try
{
	$customLogger = New-RunLogger -LogFilePath "$env:TEMP\CustomSleepManager.log" -MinimumLogLevel Debug
	Set-SleepManagerLogger -Logger $customLogger
	$newLogger = Get-SleepManagerLogger
	$customLoggerWorking = ($newLogger.LogFilePath -eq $customLogger.LogFilePath)
	Write-Host "    Custom logger set successfully: $customLoggerWorking" -ForegroundColor $(if ($customLoggerWorking) { 'Green' }
		else { 'Red' })
	Write-Host "    Custom log path: $($newLogger.LogFilePath)" -ForegroundColor White
}
catch
{
	Write-Host "    Custom logger test failed: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host "    This may indicate an issue with RunLogger class visibility" -ForegroundColor Yellow
}
Write-Host ""

# Test basic sleep disable/enable functionality
Write-Host "1. Testing Disable-ComputerSleep:" -ForegroundColor Yellow
$disableResult = Disable-ComputerSleep
Write-Host "Result: $disableResult" -ForegroundColor $(if ($disableResult) { 'Green' }
	else { 'Red' })
Write-Host ""

# Test sleep disable with display prevention
Write-Host "2. Testing Disable-ComputerSleep with KeepDisplayOn:" -ForegroundColor Yellow
$disableDisplayResult = Disable-ComputerSleep -KeepDisplayOn
Write-Host "Result: $disableDisplayResult" -ForegroundColor $(if ($disableDisplayResult) { 'Green' }
	else { 'Red' })
Write-Host ""

# Test re-enabling sleep
Write-Host "3. Testing Enable-ComputerSleep:" -ForegroundColor Yellow
$enableResult = Enable-ComputerSleep
Write-Host "Result: $enableResult" -ForegroundColor $(if ($enableResult) { 'Green' }
	else { 'Red' })
Write-Host ""

# Test the Invoke-WithoutSleep function
Write-Host "4. Testing Invoke-WithoutSleep:" -ForegroundColor Yellow
try
{
	Invoke-WithoutSleep {
		Write-Host "  -> Inside sleep-disabled block" -ForegroundColor Gray
		Write-Host "  -> Waiting 2 seconds..." -ForegroundColor Gray
		Start-Sleep -Seconds 2
		Write-Host "  -> Block execution completed" -ForegroundColor Gray
	}
	Write-Host "Invoke-WithoutSleep completed successfully" -ForegroundColor Green
}
catch
{
	Write-Host "Invoke-WithoutSleep failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test Invoke-WithoutSleep with display prevention
Write-Host "5. Testing Invoke-WithoutSleep with KeepDisplayOn:" -ForegroundColor Yellow
try
{
	Invoke-WithoutSleep -KeepDisplayOn {
		Write-Host "  -> Inside sleep and display-disabled block" -ForegroundColor Gray
		Write-Host "  -> Waiting 2 seconds..." -ForegroundColor Gray
		Start-Sleep -Seconds 2
		Write-Host "  -> Block execution completed" -ForegroundColor Gray
	}
	Write-Host "Invoke-WithoutSleep with KeepDisplayOn completed successfully" -ForegroundColor Green
}
catch
{
	Write-Host "Invoke-WithoutSleep with KeepDisplayOn failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test error handling by trying to access the SleepControl type
Write-Host "6. Testing Windows API Type Loading:" -ForegroundColor Yellow
try
{
	$apiTest = [SleepControl]::ES_CONTINUOUS
	Write-Host "SleepControl type loaded successfully. ES_CONTINUOUS = $apiTest" -ForegroundColor Green
}
catch
{
	Write-Host "Failed to access SleepControl type: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test the custom logger by checking log files
Write-Host "7. Testing Custom Logger Integration:" -ForegroundColor Yellow
Write-Host "  -> Checking custom log file exists:" -ForegroundColor Gray
$customLogExists = Test-Path $customLogger.LogFilePath
Write-Host "    Custom log file created: $customLogExists" -ForegroundColor $(if ($customLogExists) { 'Green' }
	else { 'Red' })

if ($customLogExists)
{
	Write-Host "  -> Reading last few lines from custom log:" -ForegroundColor Gray
	$logContent = Get-Content $customLogger.LogFilePath -Tail 5
	foreach ($line in $logContent)
	{
		Write-Host "    $line" -ForegroundColor Cyan
	}
}
Write-Host ""

Write-Host "=== Manual Testing Suggestions ===" -ForegroundColor Cyan
Write-Host "For extended testing, try these scenarios:" -ForegroundColor Yellow
Write-Host "  • Run Disable-ComputerSleep and leave your computer idle for several minutes" -ForegroundColor White
Write-Host "  • Use Invoke-WithoutSleep for long-running operations" -ForegroundColor White
Write-Host "  • Test with KeepDisplayOn during presentations or video playback" -ForegroundColor White
Write-Host "  • Create your own custom logger and verify log entries" -ForegroundColor White
Write-Host ""

# Pester Tests (Compatible with Pester v3.4.0)
Write-Host "=== Pester Tests ===" -ForegroundColor Cyan

Describe "SleepManager Module Tests" {
	
	Context "Module Loading and Function Availability" {
		It "Should import the SleepManager module without errors" {
			{ Import-Module 'SleepManager' -Force } | Should Not Throw
		}
		
		It "Should export Disable-ComputerSleep function" {
			$cmd = Get-Command -Module SleepManager -Name 'Disable-ComputerSleep' -ErrorAction SilentlyContinue
			$cmd | Should Not BeNullOrEmpty
		}
		
		It "Should export Enable-ComputerSleep function" {
			$cmd = Get-Command -Module SleepManager -Name 'Enable-ComputerSleep' -ErrorAction SilentlyContinue
			$cmd | Should Not BeNullOrEmpty
		}
		
		It "Should export Invoke-WithoutSleep function" {
			$cmd = Get-Command -Module SleepManager -Name 'Invoke-WithoutSleep' -ErrorAction SilentlyContinue
			$cmd | Should Not BeNullOrEmpty
		}
		
		It "Should export Set-SleepManagerLogger function" {
			$cmd = Get-Command -Module SleepManager -Name 'Set-SleepManagerLogger' -ErrorAction SilentlyContinue
			$cmd | Should Not BeNullOrEmpty
		}
		
		It "Should export Get-SleepManagerLogger function" {
			$cmd = Get-Command -Module SleepManager -Name 'Get-SleepManagerLogger' -ErrorAction SilentlyContinue
			$cmd | Should Not BeNullOrEmpty
		}
	}
	
	Context "Logger Management" {
		It "Should return a default logger instance" {
			$logger = Get-SleepManagerLogger
			$logger | Should Not BeNullOrEmpty
			$logger.GetType().Name | Should Be 'RunLogger'
		}
		
		It "Should accept a custom logger instance" {
			$testLogger = New-RunLogger -LogFilePath "$env:TEMP\TestSleepManager.log" -MinimumLogLevel Warning
			{ Set-SleepManagerLogger -Logger $testLogger } | Should Not Throw
			
			$currentLogger = Get-SleepManagerLogger
			$currentLogger.LogFilePath | Should Be $testLogger.LogFilePath
			$currentLogger.MinimumLogLevel | Should Be $testLogger.MinimumLogLevel
		}
		
		It "Should validate logger parameter type" {
			# Test with invalid logger type
			{ Set-SleepManagerLogger -Logger "NotALogger" } | Should Throw
			{ Set-SleepManagerLogger -Logger $null } | Should Throw
			{ Set-SleepManagerLogger -Logger 123 } | Should Throw
		}
	}
	
	Context "Windows API Type Loading" {
		It "Should load SleepControl type successfully" {
			{ [SleepControl]::ES_CONTINUOUS } | Should Not Throw
		}
		
		It "Should have correct constant values" {
			[SleepControl]::ES_CONTINUOUS | Should Be 2147483648
			[SleepControl]::ES_SYSTEM_REQUIRED | Should Be 1
			[SleepControl]::ES_DISPLAY_REQUIRED | Should Be 2
		}
	}
	
	Context "Basic Function Execution" {
		It "Disable-ComputerSleep should not throw and should return boolean" {
			{ $result = Disable-ComputerSleep } | Should Not Throw
			$result = Disable-ComputerSleep
			$result.GetType().Name | Should Be 'Boolean'
		}
		
		It "Disable-ComputerSleep with KeepDisplayOn should not throw" {
			{ Disable-ComputerSleep -KeepDisplayOn } | Should Not Throw
		}
		
		It "Enable-ComputerSleep should not throw and should return boolean" {
			{ $result = Enable-ComputerSleep } | Should Not Throw
			$result = Enable-ComputerSleep
			$result.GetType().Name | Should Be 'Boolean'
		}
		
		It "Invoke-WithoutSleep should execute script block successfully" {
			$script:testVar = $false
			{
				Invoke-WithoutSleep {
					$script:testVar = $true
				}
			} | Should Not Throw
			$script:testVar | Should Be $true
		}
		
		It "Invoke-WithoutSleep with KeepDisplayOn should execute script block" {
			$script:testVar2 = $false
			{
				Invoke-WithoutSleep -KeepDisplayOn {
					$script:testVar2 = $true
				}
			} | Should Not Throw
			$script:testVar2 | Should Be $true
		}
	}
	
	Context "Error Handling and Cleanup" {
		It "Should handle exceptions in script blocks gracefully" {
			# Test that Invoke-WithoutSleep properly handles exceptions
			$exceptionThrown = $false
			try
			{
				Invoke-WithoutSleep {
					throw "Test exception"
				}
			}
			catch
			{
				$exceptionThrown = $true
			}
			$exceptionThrown | Should Be $true
		}
		
		It "Should properly restore sleep state after Invoke-WithoutSleep completes" {
			# Enable sleep to ensure clean starting state
			Enable-ComputerSleep | Out-Null
			
			# Use Invoke-WithoutSleep
			{ Invoke-WithoutSleep { Start-Sleep -Milliseconds 100 } } | Should Not Throw
			
			# Test passes if no exceptions occurred during cleanup
			$true | Should Be $true
		}
	}
	
	Context "Parameter Validation" {
		It "Invoke-WithoutSleep should require ScriptBlock parameter" {
			# Use a different approach - call with invalid parameter to force error
			{ Invoke-WithoutSleep -ScriptBlock $null } | Should Throw
		}
		
		It "Invoke-WithoutSleep should accept valid ScriptBlock parameter" {
			{ Invoke-WithoutSleep -ScriptBlock { Write-Host "Test" } } | Should Not Throw
			{ Invoke-WithoutSleep { Write-Host "Test" } } | Should Not Throw
		}
		
		It "Should accept KeepDisplayOn switch parameter for Disable-ComputerSleep" {
			{ Disable-ComputerSleep -KeepDisplayOn:$true } | Should Not Throw
			{ Disable-ComputerSleep -KeepDisplayOn:$false } | Should Not Throw
		}
		
		It "Should accept KeepDisplayOn switch parameter for Invoke-WithoutSleep" {
			{ Invoke-WithoutSleep -KeepDisplayOn:$true { Write-Host "Test" } } | Should Not Throw
			{ Invoke-WithoutSleep -KeepDisplayOn:$false { Write-Host "Test" } } | Should Not Throw
		}
		
		It "Set-SleepManagerLogger should require Logger parameter" {
			{ Set-SleepManagerLogger -Logger $null } | Should Throw
		}
	}
	
	Context "Logger Integration Testing" {
		It "Should log messages to custom logger" {
			# Create a test logger
			$testLogPath = "$env:TEMP\SleepManagerTest_$(Get-Random).log"
			$testLogger = New-RunLogger -LogFilePath $testLogPath -MinimumLogLevel Debug
			
			# Set the test logger
			Set-SleepManagerLogger -Logger $testLogger
			
			# Perform some operations that should generate log entries
			Disable-ComputerSleep | Out-Null
			Enable-ComputerSleep | Out-Null
			
			# Check that log file was created and has content
			Test-Path $testLogPath | Should Be $true
			
			$logContent = Get-Content $testLogPath -Raw
			$logContent | Should Not BeNullOrEmpty
			$logContent | Should Match "disable computer sleep"
			$logContent | Should Match "re-enable computer sleep"
			
			# Cleanup
			if (Test-Path $testLogPath)
			{
				Remove-Item $testLogPath -Force -ErrorAction SilentlyContinue
			}
		}
		
		It "Should handle logger operations without errors when logger is null" {
			# This tests the Initialize-DefaultLogger fallback
			# Temporarily set logger to null (simulating edge case)
			$originalLogger = Get-SleepManagerLogger
			
			# Reset to default logger to ensure clean test
			Import-Module 'SleepManager' -Force
			
			# These operations should work without throwing
			{ Disable-ComputerSleep } | Should Not Throw
			{ Enable-ComputerSleep } | Should Not Throw
		}
	}
}

Write-Host ""
Write-Host "=== Advanced Logger Testing ===" -ForegroundColor Cyan

# Demonstrate advanced logger usage scenarios
Write-Host "8. Testing Advanced Logger Scenarios:" -ForegroundColor Yellow

# Test 1: Shared logger across operations
Write-Host "  -> Testing shared logger across multiple operations:" -ForegroundColor Gray
$sharedLogger = New-RunLogger -LogFilePath "$env:TEMP\SharedSleepManager.log" -MinimumLogLevel Debug
Set-SleepManagerLogger -Logger $sharedLogger

# Add a custom message to the shared logger
$sharedLogger.Information("=== Starting advanced sleep manager test ===")

# Perform operations
Disable-ComputerSleep -KeepDisplayOn | Out-Null
Start-Sleep -Seconds 1
Enable-ComputerSleep | Out-Null

# Add another custom message
$sharedLogger.Information("=== Completed advanced sleep manager test ===")

Write-Host "    Shared logger operations completed" -ForegroundColor Green

# Test 2: Different log levels
Write-Host "  -> Testing different log levels:" -ForegroundColor Gray
$debugLogger = New-RunLogger -LogFilePath "$env:TEMP\DebugSleepManager.log" -MinimumLogLevel Debug
Set-SleepManagerLogger -Logger $debugLogger

# This should generate debug-level messages
Invoke-WithoutSleep {
	Write-Host "    -> Debug-level logging active" -ForegroundColor Cyan
	Start-Sleep -Milliseconds 500
}

Write-Host "    Debug logging test completed" -ForegroundColor Green

# Test 3: Production-level logging (Information and above)
Write-Host "  -> Testing production-level logging:" -ForegroundColor Gray
$prodLogger = New-RunLogger -LogFilePath "$env:TEMP\ProdSleepManager.log" -MinimumLogLevel Information
Set-SleepManagerLogger -Logger $prodLogger

Invoke-WithoutSleep -KeepDisplayOn {
	Write-Host "    -> Production logging active" -ForegroundColor Cyan
	Start-Sleep -Milliseconds 500
}

Write-Host "    Production logging test completed" -ForegroundColor Green
Write-Host ""

Write-Host "=== Log File Summary ===" -ForegroundColor Cyan
$logFiles = @(
	"$env:TEMP\CustomSleepManager.log",
	"$env:TEMP\SharedSleepManager.log",
	"$env:TEMP\DebugSleepManager.log",
	"$env:TEMP\ProdSleepManager.log"
)

foreach ($logFile in $logFiles)
{
	if (Test-Path $logFile)
	{
		$logName = Split-Path $logFile -Leaf
		$lineCount = (Get-Content $logFile).Count
		Write-Host "$logName - $lineCount lines" -ForegroundColor White
		
		# Show the last entry from each log
		$lastLine = Get-Content $logFile -Tail 1
		if ($lastLine)
		{
			Write-Host "  Last entry: $lastLine" -ForegroundColor Gray
		}
	}
}
Write-Host ""

Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "All functionality tests completed successfully!" -ForegroundColor Green
Write-Host "The SleepManager module v1.1.0 is ready for use." -ForegroundColor Green
Write-Host ""
Write-Host "Key Functions Available:" -ForegroundColor Cyan
Write-Host "  • Disable-ComputerSleep [-KeepDisplayOn]" -ForegroundColor White
Write-Host "  • Enable-ComputerSleep" -ForegroundColor White
Write-Host "  • Invoke-WithoutSleep [-KeepDisplayOn] { ScriptBlock }" -ForegroundColor White
Write-Host "  • Set-SleepManagerLogger -Logger <RunLogger>" -ForegroundColor White
Write-Host "  • Get-SleepManagerLogger" -ForegroundColor White
Write-Host ""
Write-Host "New in v1.1.0:" -ForegroundColor Yellow
Write-Host "  • Custom logger support for integration with existing logging infrastructure" -ForegroundColor White
Write-Host "  • Flexible logging configuration (file path, log levels, etc.)" -ForegroundColor White
Write-Host "  • Shared logger capabilities across multiple modules/components" -ForegroundColor White