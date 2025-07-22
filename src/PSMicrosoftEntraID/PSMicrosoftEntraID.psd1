@{
	# Script module or binary module file associated with this manifest
	RootModule         = 'PSMicrosoftEntraID.psm1'

	# Version number of this module.
	ModuleVersion      = '0.0.0'

	# ID used to uniquely identify this module
	GUID               = '3ccc09a2-90bd-4561-9069-6db4040ff4f7'

	# Author of this module
	Author             = 'Ondrej Kracmar'

	# Company or vendor of this module
	CompanyName        = 'i-System'

	# Copyright statement for this module
	Copyright          = 'Copyright (c) 2024 i-system'

	# Description of the functionality provided by this module
	Description        = 'Powershell module represents an Microsoft EntraID object'

	# Minimum version of the PowerShell engine required by this module
	PowerShellVersion  = '7.2'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules    = @('PSFramework')

	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @('bin\PSMicrosoftEntraID.dll')

	# Type files (.ps1xml) to be loayded when importing this module
	TypesToProcess     = @('types\PSMicrosoftEntraID.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess   = @('views\PSMicrosoftEntraID.Format.ps1xml')

	# cript (.ps1) files that are run in the caller's session state when the module is imported.
	#ScriptsToProcess   = ""

	# Functions to export from this module
	FunctionsToExport  = @(
		'Connect-PSMicrosoftEntraID'
		'Disconnect-PSMicrosoftEntraID'
		'Get-PSEntraIDOrganization'
		'Get-PSEntraIDMessageCenter'
		'Disable-PSEntraIDUserLicense'
		'Enable-PSEntraIDUserLicense'
		'Disable-PSEntraIDUserLicenseServicePlan'
		'Enable-PSEntraIDUserLicenseServicePlan'
		'Get-PSEntraIDUserLicense'
		'Get-PSEntraIDUserLicenseDetail'
		'Get-PSEntraIDUser'
		'Get-PSEntraIDUserGuest'
		'Get-PSEntraIDContact'
		'New-PSEntraIDUser'
		'Set-PSEntraIDUser'
		'Compare-PSEntraIDUserList'
		'Invoke-PSEntraIDBatchRequest'
		'Invoke-PSEntraIDRequest'
		'Remove-PSEntraIDUser'
		'Get-PSEntraIDUserMemberOf'
		'New-PSEntraIDInvitation'
		'Set-PSEntraIDGroup'
		'Set-PSEntraIDUserUsageLocation'
		'Get-PSEntraIDUsageLocation'
		'Get-PSEntraIDLicenseIdentifier'
		'Get-PSEntraIDSubscribedLicense'
		'Get-PSEntraIDGroup'
		'Get-PSEntraIDGroupAdditionalProperty'
		'New-PSEntraIDGroup'
		'Remove-PSEntraIDGroup'
		'Get-PSEntraIDGroupMember'
		'Add-PSEntraIDGroupMember'
		'Remove-PSEntraIDGroupMember'
		'Add-PSEntraIDGroupOwner'
		'Remove-PSEntraIDGroupOwner'
		'Sync-PSEntraIDGroupMember'
		'Set-PSEntraIDCommandRetry'
		'Get-PSEntraIDCommandRetry'
	)

	# Cmdlets to export from this module
	CmdletsToExport    = @(
		'New-PSEntraIDBatchRequest'
	)

	# Variables to export from this module
	VariablesToExport  = ''

	# Aliases to export from this module
	AliasesToExport    = ''

	# List of all modules packaged with this module
	ModuleList         = @()

	# List of all files packaged with this module
	FileList           = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData        = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags                       = @('Rest', 'Azure', 'AzureActiveDirectory', 'MicrosoftEntra', 'MicrosoftEntraID')
			ExternalModuleDependencies = @('PSFramework')

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}