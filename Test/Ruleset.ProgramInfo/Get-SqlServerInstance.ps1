
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

<#
.SYNOPSIS
Unit test for Get-SqlServerInstance

.DESCRIPTION
Test correctness of Get-SqlServerInstance function

.PARAMETER Force
If specified, no prompt to run script is shown

.EXAMPLE
PS> .\Get-SqlServerInstance.ps1

.INPUTS
None. You cannot pipe objects to Get-SqlServerInstance.ps1

.OUTPUTS
None. Get-SqlServerInstance.ps1 does not generate any output

.NOTES
TODO: Test not working in Windows PowerShell
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
	[Parameter()]
	[switch] $Force
)

#region Initialization
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1 $PSCmdlet
. $PSScriptRoot\..\ContextSetup.ps1

Initialize-Project -Strict
if (!(Approve-Execute -Accept $Accept -Deny $Deny -Force:$Force)) { exit }
#endregion

Enter-Test "Get-SqlServerInstance"

Start-Test "default"
$Instances = Get-SqlServerInstance
$Instances

Start-Test "CIM"
Get-SqlServerInstance -CIM

# TODO: Format-Wide when InstallLocation is available
Start-Test "binn directory"
Get-SqlServerInstance | Select-Object -ExpandProperty SQLBinRoot

Start-Test "DTS directory"
Get-SqlServerInstance | Select-Object -ExpandProperty SQLPath

Test-Output $Instances -Command Get-SqlServerInstance

Update-Log
Exit-Test
