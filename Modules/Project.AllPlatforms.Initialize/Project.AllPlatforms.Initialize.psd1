
#
# Module manifest for module "Project.AllPlatforms.Initialize"
#
# Generated by: metablaster
#
# Generated on: 12.2.2020.
#

@{
	# Script module or binary module file associated with this manifest.
	RootModule = "Project.AllPlatforms.Initialize.psm1"

	# Version number of this module.
	ModuleVersion = "0.5.1"

	# Supported PSEditions
	CompatiblePSEditions = "Core, Desktop"

	# ID used to uniquely identify this module
	GUID = "41585bd3-3f4d-4669-9919-2d19c0451b73"

	# Author of this module
	Author = "metablaster zebal@protonmail.ch"

	# Company or vendor of this module
	# CompanyName = "Unknown"

	# Copyright statement for this module
	Copyright = "Copyright (C) 2019, 2020 metablaster"

	# Description of the functionality provided by this module
	Description = "Initialize environment for Windows Firewall Ruleset project"

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = "5.1"

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ""

	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ""

	# Minimum version of Microsoft .NET Framework required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	DotNetFrameworkVersion = "3.5"

	# Minimum version of the common language runtime (CLR) required by this module.
	# This prerequisite is valid for the PowerShell Desktop edition only.
	CLRVersion = "2.0"

	# Processor architecture (None, X86, Amd64) required by this module
	ProcessorArchitecture = "None"

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# TODO: Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport = @(
		"Initialize-Project"
		"Initialize-Service"
		"Initialize-Module"
		"Initialize-Provider"
	)

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module
	VariablesToExport = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not
	# delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
	FileList = @(
		"Initialize-Module.ps1"
		"Initialize-Project.ps1"
		"Initialize-Provider.ps1"
		"Initialize-Service.ps1"
		"Project.AllPlatforms.Initialize.psd1"
		"Project.AllPlatforms.Initialize.psm1"
		"about_Project.AllPlatforms.Initialize.help.txt"
	)

	# Private data to pass to the module specified in RootModule/ModuleToProcess.
	# This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @("Initialization", "Environment")

			# A URL to the license for this module.
			LicenseUri = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/LICENSE"

			# A URL to the main website for this project.
			ProjectUri = "https://github.com/metablaster/WindowsFirewallRuleset"

			# A URL to an icon representing this module.
			# IconUri = ""

			# ReleaseNotes of this module
			ReleaseNotes = "Pre-release module to initialize environment for 'Windows Firewall Ruleset' project"
		} # End of PSData hashtable
	} # End of PrivateData hashtable

	# HelpInfo URI of this module
	HelpInfoURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/README.md"

	# Default prefix for commands exported from this module.
	# Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ""
}
