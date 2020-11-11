
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements
Initialize-Project -Abort

# Imports
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name Ruleset.Logging
Import-Module -Name Ruleset.UserInfo

# Setup local variables
$Group = "Software - DnsCrypt"
$FirewallProfile = "Private, Public"
$Accept = "Outbound rules for DnsCrypt software will be loaded, recommended if DnsCrypt software is installed to let it access to network"
$Deny = "Skip operation, outbound rules for DnsCrypt software will not be loaded into firewall"

# User prompt
Update-Context "IPv$IPVersion" $Direction $Group @Logs
if (!(Approve-Execute -Accept $Accept -Deny $Deny @Logs)) { exit }

# First remove -PolicyStore $PolicyStore all existing rules matching grou-Group $Group p
Remove-NetFirewallRule -Direction $Direction -ErrorAction Ignore @Logs

#
# DnsCrypt installation directories
#
$DnsCryptRoot = "%ProgramFiles%\Simple DNSCrypt x64"

#
# DnsCrypt rules
# TODO: remote servers from file, explicit TCP or UDP
# HACK: If localhost (DNSCrypt) is the only DNS server (no secondary DNS) then network status will be
# "No internet access" even though internet works just fine
# TODO: Add rule for "Global resolver", dnscrypt-proxy acting as server
#

# Test if installation exists on system
if ((Test-Installation "DnsCrypt" ([ref] $DnsCryptRoot) @Logs) -or $ForceLoad)
{
	$Program = "$DnsCryptRoot\dnscrypt-proxy\dnscrypt-proxy.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "dnscrypt-proxy" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 443 `
		-LocalUser $NT_AUTHORITY_System `
		-InterfaceType $Interface `
		-Description "DNSCrypt is a protocol that authenticates communications between a DNS client and a DNS resolver.
	It prevents DNS spoofing. It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver and haven't been tampered with.
	This rule applies to Simple DnsCrypt which uses dnscrypt-proxy for DOH protocol" @Logs | Format-Output @Logs

	# TODO: see if LooseSourceMapping is needed
	New-NetFirewallRule -DisplayName "dnscrypt-proxy" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol UDP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort Any `
		-LocalUser $NT_AUTHORITY_System `
		-LocalOnlyMapping $false -LooseSourceMapping $false `
		-InterfaceType $Interface `
		-Description "DNSCrypt is a protocol that authenticates communications between a DNS client and a DNS resolver.
	It prevents DNS spoofing. It uses cryptographic signatures to verify that responses originate from the chosen DNS resolver and haven't been tampered with.
	This rule applies to Simple DnsCrypt which uses dnscrypt-proxy for DnsCrypt Protocol" @Logs | Format-Output @Logs

	$Program = "$DnsCryptRoot\SimpleDnsCrypt.exe"
	Test-File $Program @Logs
	New-NetFirewallRule -DisplayName "Simple DNS Crypt" `
		-Platform $Platform -PolicyStore $PolicyStore -Profile $FirewallProfile `
		-Service Any -Program $Program -Group $Group `
		-Enabled True -Action Allow -Direction $Direction -Protocol TCP `
		-LocalAddress Any -RemoteAddress Internet4 `
		-LocalPort Any -RemotePort 80, 443 `
		-LocalUser $AdministratorsGroupSDDL `
		-InterfaceType $Interface `
		-Description "Simple DNS Crypt update check on startup" @Logs | Format-Output @Logs
}

Update-Log
