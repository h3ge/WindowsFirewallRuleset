
<#
MIT License

This file is part of "Windows Firewall Ruleset" project
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2020 metablaster zebal@protonmail.ch

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
Module script experiment

.DESCRIPTION
Use Test-Function.ps1 to write temporary module tests

.EXAMPLE
PS> Import-Module -Name Experiment.Module
PS> Test-Function

.INPUTS
None. You cannot pipe objects to Test-Function.ps1

.OUTPUTS
None. Test-Function.ps1 does not generate any output

.NOTES
None.
#>
function Test-Function
{
	[CmdletBinding()]
	param (
		[Parameter()]
		[string] $Param
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] params($($PSBoundParameters.Values))"

	$InformationPreference = "Continue"

	Write-Information -MessageData "Parameter: $Param"
}

# Template variable
Set-Variable -Name TestVariable -Scope Script -Value "Test variable"

# Out of a module context
if ($MyInvocation.InvocationName -ne '.')
{
	Test-Function $TestVariable
}