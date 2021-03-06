
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020, 2021 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

<#PSScriptInfo

.VERSION 0.10.0

.GUID 16cf3c56-2a61-4a72-8f06-6f8165ed6115

.AUTHOR metablaster zebal@protonmail.com
#>

<#
.SYNOPSIS
Grant permissions to read and write firewall logs in custom location

.DESCRIPTION
When firewall is set to write logs into custom location inside repository, neither firewall service
nor users can access them.
Grant permissions to non administrative account to read firewall log files.
Also grants firewall service to write logs to project specified location.
The Microsoft Protection Service will automatically reset permissions on firewall logs either
on system reboot, network reconnect or firewall settings change, for security reasons.

.PARAMETER User
Non administrative user account for which to grant permission

.PARAMETER Domain
Principal domain for which to grant permission.
By default specified principal gets permission from local machine

.PARAMETER Force
If specified, no prompt for confirmation is shown to perform actions

.EXAMPLE
PS> .\Grant-Logs.ps1 USERNAME

.EXAMPLE
PS> .\Grant-Logs.ps1 USERNAME -Domain COMPUTERNAME

.INPUTS
None. You cannot pipe objects to Grant-Logs.ps1

.OUTPUTS
None. Grant-Logs.ps1 does not generate any output

.NOTES
Running this script makes sense only for custom firewall log location inside repository.
The benefit is to have special syntax coloring and filtering functionality with VSCode.
First time setup requires turning off/on Windows firewall for current network profile in order for
Windows firewall to start logging into new location.
TODO: Need to verify if gpupdate is needed for first time setup and if so update Complete-Firewall.ps1

.LINK
https://github.com/metablaster/WindowsFirewallRuleset/tree/master/Scripts
#>

using namespace System.Security
#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding = $false)]
[OutputType([void])]
param (
	[Parameter(Position = 0)]
	[Alias("UserName")]
	[string] $User = $DefaultUser,

	[Parameter()]
	[Alias("ComputerName", "CN")]
	[string] $Domain = [System.Environment]::MachineName,

	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\Config\ProjectSettings.ps1 $PSCmdlet
Initialize-Project -Strict

# User prompt
$Accept = "Grant permission to read firewall log files until system reboot"
$Deny = "Abort operation, no permission change is done on firewall logs"
if (!(Approve-Execute -Accept $Accept -Unsafe -Deny $Deny -Force:$Force)) { exit }
#endregion

Write-Verbose -Message "[$ThisScript] Verifying firewall log file location"

if (!(Compare-Path -Loose $FirewallLogsFolder -ReferencePath "$ProjectRoot\*"))
{
	# Continue only if firewall logs go to location inside repository
	Write-Warning -Message "Not granting permissions for $FirewallLogsFolder"
	exit
}

# NOTE: FirewallLogsFolder may contain environment variable
$TargetFolder = [System.Environment]::ExpandEnvironmentVariables($FirewallLogsFolder)

if (!(Test-Path -Path $TargetFolder -PathType Container))
{
	# Create directory for firewall logs if it doesn't exist
	New-Item -Path $TargetFolder -ItemType Container | Out-Null
}

# Change in logs location will require system reboot
Write-Information -Tags "Project" -MessageData "INFO: Verifying if there is change in log location"
# TODO: Get-NetFirewallProfile: "An unexpected network error occurred",
# happens proably if network is down or adapter not configured?
$OldLogFiles = Get-NetFirewallProfile -PolicyStore $PolicyStore -All |
Select-Object -ExpandProperty LogFileName | Split-Path

[string[]] $OldLocation = @()
foreach ($File in $OldLogFiles)
{
	$OldLocation += [System.Environment]::ExpandEnvironmentVariables($File)
}

# Setup control rights
$UserControl = [AccessControl.FileSystemRights] "ReadAndExecute, WriteData, Write"
$FullControl = [AccessControl.FileSystemRights]::FullControl

# Grant "FullControl" to firewall service for logs folder
Write-Information -Tags "User" -MessageData "INFO: Granting full control to firewall service for log directory"

Set-Permission $TargetFolder -Owner "System" -Force:$Force | Out-Null
Set-Permission $TargetFolder -User "System" -Rights $FullControl -Protected -Force:$Force | Out-Null
Set-Permission $TargetFolder -User "Administrators" -Rights $FullControl -Protected -Force:$Force | Out-Null
Set-Permission $TargetFolder -User "mpssvc" -Domain "NT SERVICE" -Rights $FullControl -Protected -Force:$Force | Out-Null

$StandardUser = $true
foreach ($Admin in $(Get-GroupPrincipal -Group "Administrators" -Domain $Domain))
{
	if ($User -eq $Admin.User)
	{
		Write-Warning -Message "User '$User' belongs to Administrators group, no need to grant permission"
		$StandardUser = $false
		break
	}
}

if ($StandardUser)
{
	# Grant "Read & Execute" to user for firewall logs
	Write-Information -Tags "User" -MessageData "INFO: Granting limited permissions to user '$User' for log directory"
	if (Set-Permission $TargetFolder -User $User -Domain $Domain -Rights $UserControl -Force:$Force)
	{
		# NOTE: For -Exclude we need -Path DIRECTORY\* to get file names instead of file contents
		foreach ($LogFile in $(Get-ChildItem -Path $TargetFolder\* -Filter *.log -Exclude *.filterline.log))
		{
			Write-Verbose -Message "[$ThisScript] Processing: $LogFile"
			Set-Permission $LogFile.FullName -User $User -Domain $Domain -Rights $UserControl -Force:$Force | Out-Null
		}
	}
}

# If there is at least one change in logs location reboot is required
foreach ($Location in $OldLocation)
{
	if (!(Compare-Path $Location $TargetFolder))
	{
		Write-Warning -Message "System reboot is required for firewall logging path changes"
		break
	}
}

Update-Log
