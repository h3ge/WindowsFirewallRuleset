
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019-2021 metablaster zebal@protonmail.ch

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

<#
.SYNOPSIS
Outbound firewall rules for GitHub

.DESCRIPTION
Outbound firewall rules for git and GitHub Desktop

.EXAMPLE
PS> .\GitHub.ps1

.INPUTS
None. You cannot pipe objects to GitHub.ps1

.OUTPUTS
None. GitHub.ps1 does not generate any output

.NOTES
None.
#>

#region Initialization
#Requires -RunAsAdministrator
. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Development - GitHub"
$Accept = "Outbound rules for 'Git' and 'GitHub Desktop' are recommended if these programs are installed"
$Deny = "Skip operation, these rules will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Git and Git Desktop installation directories
#
$GitRoot = "%ProgramFiles%\Git"
$GitHubRoot = "%SystemDrive%\Users\$DefaultUser\AppData\Local\Apps\GitHubDesktop"

#
# Rules for git
#

# Test if installation exists on system
if ((Confirm-Installation "Git" ([ref] $GitRoot)) -or $ForceLoad)
{
	# Administrators are needed for git auto update scheduled task
	$CurlUsers = Get-SDDL -Group "Administrators", "Users" -Merge
	$Program = "$GitRoot\mingw64\bin\curl.exe"
	Test-ExecutableFile $Program

	New-NetFirewallRule -DisplayName "Git - curl" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $CurlUsers `
		-InterfaceType $DefaultInterface `
		-Description "curl download tool, also used by Git for Windows updater
curl is a commandline tool to transfer data from or to a server,
using one of the supported protocols:
(DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, POP3, POP3S, RTMP,
RTMPS, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP)" |
	Format-Output

	# TODO: unsure if it's 443 or 80, and not sure what's the purpose
	$Program = "$GitRoot\mingw64\bin\git.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -DisplayName "Git - git" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "" | Format-Output

	$Program = "$GitRoot\mingw64\libexec\git-core\git-remote-https.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -DisplayName "Git - remote-https" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "git HTTPS for clone, fetch, push, commit etc." | Format-Output

	$Program = "$GitRoot\usr\bin\ssh.exe"
	Test-ExecutableFile $Program
	New-NetFirewallRule -DisplayName "Git - ssh" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled False -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 22 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "SSH client for git clone, fetch, push, commit etc." | Format-Output
}

#
# Rules for GitHub desktop
#

# Test if installation exists on system
if ((Confirm-Installation "GitHubDesktop" ([ref] $GitHubRoot)) -or $ForceLoad)
{
	$ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($GitHubRoot)

	if ($ForceLoad -and !(Test-Path -Path $ExpandedPath -PathType Container))
	{
		$VersionFolders = $null
	}
	else
	{
		$VersionFolders = Get-ChildItem -Directory -Path $ExpandedPath -Filter app-* -Name
	}

	$VersionFoldersCount = ($VersionFolders | Measure-Object).Count

	if ($VersionFoldersCount -gt 0)
	{
		$VersionFolder = $VersionFolders | Sort-Object | Select-Object -Last 1
		$Program = "$GitHubRoot\$VersionFolder\GitHubDesktop.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GitHubRoot\app-2.6.1\GitHubDesktop.exe"
	}

	Test-ExecutableFile $Program

	New-NetFirewallRule -DisplayName "GitHub Desktop - Client" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "At a minimum telemetry and authentication to GitHub" | Format-Output

	$Program = "$GitHubRoot\Update.exe"
	Test-ExecutableFile $Program

	New-NetFirewallRule -DisplayName "GitHub Desktop - Update" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "Checking for client updates and client auto update" | Format-Output

	if ($VersionFoldersCount -gt 0)
	{
		# $VersionDirectory = $VersionFolders.Name
		$Program = "$GitHubRoot\$VersionFolder\resources\app\git\mingw64\bin\git-remote-https.exe"
	}
	else
	{
		# Let user know what is the likely path
		$Program = "$GitHubRoot\app-2.6.1\resources\app\git\mingw64\bin\git-remote-https.exe"
	}

	Test-ExecutableFile $Program

	New-NetFirewallRule -DisplayName "GitHub Desktop - Git" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $DefaultProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $UsersGroupSDDL `
		-InterfaceType $DefaultInterface `
		-Description "Used for clone, fetch, push, commit etc." | Format-Output
}

Update-Log
