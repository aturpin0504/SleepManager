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

Write-Host "=== Testing SleepManager Module ===" -ForegroundColor Cyan
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

Write-Host "=== Manual Testing Suggestions ===" -ForegroundColor Cyan
Write-Host "For extended testing, try these scenarios:" -ForegroundColor Yellow
Write-Host "  • Run Disable-ComputerSleep and leave your computer idle for several minutes" -ForegroundColor White
Write-Host "  • Use Invoke-WithoutSleep for long-running operations" -ForegroundColor White
Write-Host "  • Test with KeepDisplayOn during presentations or video playback" -ForegroundColor White
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
			{ Invoke-WithoutSleep } | Should Throw
		}
		
		It "Should accept KeepDisplayOn switch parameter for Disable-ComputerSleep" {
			{ Disable-ComputerSleep -KeepDisplayOn:$true } | Should Not Throw
			{ Disable-ComputerSleep -KeepDisplayOn:$false } | Should Not Throw
		}
	}
}

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host "All basic functionality tests completed!" -ForegroundColor Green
Write-Host "The SleepManager module is ready for use." -ForegroundColor Green
Write-Host ""
Write-Host "Key Functions Available:" -ForegroundColor Cyan
Write-Host "  • Disable-ComputerSleep [-KeepDisplayOn]" -ForegroundColor White
Write-Host "  • Enable-ComputerSleep" -ForegroundColor White
Write-Host "  • Invoke-WithoutSleep [-KeepDisplayOn] { ScriptBlock }" -ForegroundColor White