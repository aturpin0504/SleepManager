<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.256
	 Created on:   	5/27/2025 8:51 PM
	 Created by:   	aaturpin
	 Organization: 	
	 Filename:     	SleepManager.psd1
	 -------------------------------------------------------------------------
	 Module Manifest
	-------------------------------------------------------------------------
	 Module Name: SleepManager
	===========================================================================
#>


@{
	
	# Script module or binary module file associated with this manifest
	RootModule			   = 'SleepManager.psm1'
	
	# Version number of this module.
	ModuleVersion		   = '1.0.0'
	
	# ID used to uniquely identify this module
	GUID				   = 'c8218ab2-673a-4544-a2f6-a96747e3b734'
	
	# Author of this module
	Author				   = 'aaturpin'
	
	# Company or vendor of this module
	CompanyName		       = ''
	
	# Copyright statement for this module
	Copyright			   = '(c) 2025. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description		       = 'PowerShell module for managing computer sleep and display power states using Windows API. Provides functions to disable/enable sleep mode and execute code blocks with sleep prevention. Includes comprehensive logging via RunLog module.'
	
	# Supported PSEditions
	# CompatiblePSEditions = @('Core', 'Desktop')
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion	   = '5.1'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName	   = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion  = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.5.2'
	
	# Minimum version of the common language runtime (CLR) required by this module
	# CLRVersion = ''
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture  = 'None'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules	       = @(
		@{
			ModuleName    = 'RunLog'
			ModuleVersion = '2.0.0'
		}
	)
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies	   = @()
	
	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess	   = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess		   = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess	   = @()
	
	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	NestedModules		   = @()
	
	# Functions to export from this module
	FunctionsToExport	   = @(
		'Disable-ComputerSleep',
		'Enable-ComputerSleep',
		'Invoke-WithoutSleep'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport	       = @()
	
	# Variables to export from this module
	VariablesToExport	   = @()
	
	# Aliases to export from this module
	AliasesToExport	       = @()
	
	# DSC class resources to export from this module.
	#DSCResourcesToExport = ''
	
	# List of all modules packaged with this module
	ModuleList			   = @()
	
	# List of all files packaged with this module
	FileList			   = @(
		'SleepManager.psd1',
		'SleepManager.psm1',
		'README.md'
	)
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData		       = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags		 = @('Sleep', 'Power', 'Windows', 'API', 'System', 'Display', 'PowerManagement', 'Logging')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/aturpin0504/SleepManager?tab=MIT-1-ov-file'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/aturpin0504/SleepManager'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'Initial release - Provides functions to disable/enable computer sleep mode and execute code blocks with sleep prevention using Windows API.'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}