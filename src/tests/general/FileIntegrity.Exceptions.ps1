# List of forbidden commands
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$global:BannedCommands = @(
	'Write-Host'
	'Write-Verbose'
	'Write-Warning'
	'Write-Error'
	'Write-Output'
	'Write-Information'
	'Write-Debug'
	
	# Use CIM instead where possible
	'Get-WmiObject'
	'Invoke-WmiMethod'
	'Register-WmiEvent'
	'Remove-WmiObject'
	'Set-WmiInstance'

	# Use Get-WinEvent instead
	'Get-EventLog'
)

<#
	Contains list of exceptions for banned cmdlets.
	Insert the file names of files that may contain them.
	
	Example:
	"Write-Host"  = @('Write-PSFHostColor.ps1','Write-PSFMessage.ps1')
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$global:MayContainCommand = @{
	# The sign-in flows and the request layer write through Write-PSFMessage only (localized, and the request URL
	# without its query): they are no longer exceptions here, so a Write-* that comes back fails this test.
	"Write-Host"  = @()
	"Write-Verbose" = @('Disconnect-PSMicrosoftEntraID.ps1','Connect-EntraService.ps1')
	"Write-Warning" = @('assembly.ps1','Connect-PSMicrosoftEntraID.ps1','Connect-EntraService.ps1','Assert-ServiceName.ps1','federationproviders.ps1')
	"Write-Error"  = @()
	"Write-Output" = @()
	"Write-Information" = @()
	"Write-Debug" = @()
}