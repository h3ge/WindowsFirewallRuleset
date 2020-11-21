
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

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
Outbound firewall rules for Java

.DESCRIPTION
Outbound firewall rules for Java software suite

.EXAMPLE
PS> .\Java.ps1

.INPUTS
None. You cannot pipe objects to Java.ps1

.OUTPUTS
None. Java.ps1 does not generate any output

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
$Group = "Software - Java"
$Accept = "Outbound rules for Java software will be loaded, recommended if Java software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for Java software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute -Accept $Accept -Deny $Deny)) { exit }
#endregion

#
# Java installation directories
#
$JavaRuntimeRoot = "%ProgramFiles%\Java\jre7\bin"
$JavaPluginRoot = "%ProgramFiles(x86)%\Java\jre1.8.0_45\bin"
$JavaUpdateRoot = "%ProgramFiles(x86)%\Common Files\Java\Java Update"

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction Ignore

#
# Rules for Java
#

# Test if installation exists on system
if ((Test-Installation "JavaRuntime" ([ref] $JavaRuntimeRoot)) -or $ForceLoad)
{
	$Program = "$JavaRuntimeRoot\java.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Run java applets" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Run java applets" | Format-Output
}

# Test if installation exists on system
if ((Test-Installation "JavaUpdate" ([ref] $JavaUpdateRoot)) -or $ForceLoad)
{
	$Program = "$JavaUpdateRoot\jucheck.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Java update" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80, 443 `
		-LocalUser $UsersGroupSDDL `
		-Description "Update java software" | Format-Output
}

# Test if installation exists on system
if ((Test-Installation "JavaPlugin" ([ref] $JavaPluginRoot)) -or $ForceLoad)
{
	$Program = "$JavaPluginRoot\jp2launcher.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
		-DisplayName "Java Plugin HTTP" -Service Any -Program $Program `
		-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $DefaultProfile -InterfaceType $DefaultInterface `
		-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 80 `
		-LocalUser $UsersGroupSDDL `
		-Description "Run java applets" | Format-Output
}

Update-Log
