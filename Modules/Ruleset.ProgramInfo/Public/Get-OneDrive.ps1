
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
Get One Drive information for specific user

.DESCRIPTION
Search installed One Drive instance in userprofile for specific user account

.PARAMETER User
User name in form of "USERNAME"

.PARAMETER Domain
NETBIOS Computer name in form of "COMPUTERNAME"

.EXAMPLE
PS> Get-OneDrive "USERNAME"

.EXAMPLE
PS> Get-OneDrive "USERNAME" -Domain "Server01"

.INPUTS
None. You cannot pipe objects to Get-OneDrive

.OUTPUTS
[PSCustomObject] OneDrive program info for specified user on a target computer

.NOTES
TODO: We should make a query for an array of users, will help to save into variable,
this is duplicate comment of Get-UserSoftware
TODO: The logic of this function should probably be part of Get-UserSoftware, it is unknown
if OneDrive can be installed for all users too.
#>
function Get-OneDrive
{
	[CmdletBinding(
		HelpURI = "https://github.com/metablaster/WindowsFirewallRuleset/blob/master/Modules/Ruleset.ProgramInfo/Help/en-US/Get-OneDrive.md")]
	[OutputType([System.Management.Automation.PSCustomObject])]
	param (
		[Parameter(Mandatory = $true)]
		[Alias("UserName")]
		[string] $User,

		[Parameter()]
		[Alias("ComputerName", "CN")]
		[string] $Domain = [System.Environment]::MachineName
	)

	Write-Debug -Message "[$($MyInvocation.InvocationName)] ParameterSet = $($PSCmdlet.ParameterSetName):$($PSBoundParameters | Out-String)"
	Write-Verbose -Message "[$($MyInvocation.InvocationName)] Contacting computer: $Domain"

	if (Test-TargetComputer $Domain)
	{
		$UserSID = Get-PrincipalSID $User -Domain $Domain

		Write-Verbose -Message "[$($MyInvocation.InvocationName)] Accessing registry on computer: $Domain"
		$RegistryHive = [Microsoft.Win32.RegistryHive]::Users
		$RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Domain)

		# Check if target user is logged in (has it's reg hive loaded)
		[bool] $ReleaseHive = $false
		if ([array]::Find($RemoteKey.GetSubKeyNames(), [System.Predicate[string]] { $UserSID -eq $args[0] }))
		{
			$HKU = "$UserSID\Software\Microsoft\OneDrive"
		}
		else
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] User '$User' is not logged into system"

			# TODO: We need environment variable for remote computer
			$UserRegConfig = "$env:SystemDrive\Users\$User\NTUSER.DAT"

			# NOTE: Using User-UserName instead of SID to minimize the chance of existing key with same name
			$TempKey = "User-$User" # $UserSID

			if (Test-Path -Path $UserRegConfig)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Loading offline hive for user '$User' to HKU:$TempKey"

				# NOTE: Start-Process is needed to make the command finish it's job and print status
				$Status = Invoke-Process -NoNewWindow reg.exe -ArgumentList "load HKU\$TempKey $UserRegConfig" -Raw

				Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Status"
				$ReleaseHive = $true
				$HKU = "$TempKey\Software\Microsoft\OneDrive"
			}
			else
			{
				Write-Warning -Message "Failed to locate user registry config: $UserRegConfig"
				return
			}
		}

		try
		{
			Write-Verbose -Message "[$($MyInvocation.InvocationName)] Opening root key HKU:$HKU"
			$OneDriveKey = $RemoteKey.OpenSubkey($HKU)
		}
		catch
		{
			Write-Debug -Message "[$($MyInvocation.InvocationName)] Exception opening registry root key: HKU:$HKU"
			if ($ReleaseHive)
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Unloading and release hive HKU:$TempKey"
				[gc]::collect()
				$Status = Invoke-Process reg.exe -NoNewWindow -ArgumentList "unload HKU\$TempKey" -Raw
				Write-Debug -Message "[$($MyInvocation.InvocationName)] $Status"
			}
		}

		if (!$OneDriveKey)
		{
			Write-Warning -Message "Failed to open registry root key: HKU:$HKU"
		}
		else
		{
			$OneDrivePath = $OneDriveKey.GetValue("OneDriveTrigger")

			if ([string]::IsNullOrEmpty($OneDrivePath))
			{
				Write-Warning -Message "Failed to read registry entry $HKU\OneDriveTrigger"
			}
			else
			{
				Write-Debug -Message "[$($MyInvocation.InvocationName)] Processing key: $OneDriveKey"

				# NOTE: remove executable file name
				$InstallLocation = Split-Path -Path $OneDrivePath -Parent

				# NOTE: Avoid spamming
				$InstallLocation = Format-Path $InstallLocation #-Verbose:$false -Debug:$false

				# Get more key entries as needed
				[PSCustomObject]@{
					Domain = $Domain
					Name = "OneDrive"
					Version = $OneDriveKey.GetValue("Version")
					Publisher = "Microsoft Corporation"
					InstallLocation = $InstallLocation
					UserFolder = $OneDriveKey.GetValue("UserFolder")
					RegistryKey = "HKU:\$UserSID\Software\Microsoft\OneDrive"
					PSTypeName = "Ruleset.ProgramInfo"
				}
			}

			# key loaded with 'reg load' has to be closed, if not 'reg unload' fails with "Access is denied"
			# TODO: We close the key regardless, other functions using registry should also implement closing keys
			$OneDriveKey.Close()

			if ($ReleaseHive)
			{
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] Unload and release hive HKU:$TempKey"
				[gc]::collect()
				$Status = Invoke-Process reg.exe -NoNewWindow -ArgumentList "unload HKU\$TempKey" -Raw
				Write-Verbose -Message "[$($MyInvocation.InvocationName)] $Status"
			}
		}
	}
}
