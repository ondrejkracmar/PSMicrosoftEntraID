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
	Description        = 'Administer Microsoft Entra ID from PowerShell over Microsoft Graph: users and guests, groups and their members, administrative units, contacts, devices, organization and Message Center, licence assignment down to individual service plans, batched requests, and incremental (delta) reads with resumable sessions. Returns typed objects rather than raw JSON.'

	# Minimum version of the PowerShell engine required by this module.
	# The net8.0 build of the library references System.Management.Automation 7.4,
	# which sets the floor; PowerShell 7.6+ loads the net10.0 build instead.
	PowerShellVersion  = '7.4'

	# The compiled library targets net8.0/net10.0, so Desktop cannot load it. Saying so
	# here is what lets the gallery show the compatibility badge and stops Windows
	# PowerShell users installing something that can never import.
	CompatiblePSEditions = @('Core')

	# Modules that must be imported into the global environment prior to importing
	# this module.
	#
	# The version floor is the lowest PSFramework the test suite has actually been run
	# against. Without a floor, any PSFramework at all satisfies the manifest - including
	# versions predating features in use (Invoke-PSFProtectedCommand's retry parameters,
	# Register-PSFTeppScriptblock -Mode Full), which fail at runtime with a message that
	# does not name the cause. Lower it when someone verifies a lower version.
	RequiredModules    = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.14.450' }
	)

	# The library ships per target framework (bin/net8.0, bin/net10.0) and is loaded by
	# bin/assembly.ps1, which picks the folder matching the running .NET runtime -
	# a static RequiredAssemblies path cannot express that.
	RequiredAssemblies = @()

	# Type files (.ps1xml) to be loayded when importing this module
	TypesToProcess     = @('types\PSMicrosoftEntraID.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess   = @('views\PSMicrosoftEntraID.Format.ps1xml')

	# cript (.ps1) files that are run in the caller's session state when the module is imported.
	#ScriptsToProcess   = ""

	# Functions to export from this module
	FunctionsToExport  = @(
		'Get-PSEntraIDUserDelta'
		'Get-PSEntraIDGroupDelta'
		'Get-PSEntraIDDeviceDelta'
		'Get-PSEntraIDContactDelta'
		'Get-PSEntraIDAdministrativeUnitDelta'
		'Export-PSEntraIDDeltaSession'
		'Import-PSEntraIDDeltaSession'
		'Connect-PSMicrosoftEntraID'
		'Disconnect-PSMicrosoftEntraID'
		'Get-PSEntraIDOrganization'
		'Get-PSEntraIDMessageCenter'
		'Get-PSEntraIDDevice'
		'Set-PSEntraIDDeviceExtensionAttribute'
		'Get-PSEntraIDMachine'
		'Add-PSEntraIDMachineTag'
		'Remove-PSEntraIDMachineTag'
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
		'Get-PSEntraIDGroupLicense'
		'Get-PSEntraIDGroupLicenseDetail'
		'Get-PSEntraIDGroupAdditionalProperty'
		'New-PSEntraIDGroup'
		'Remove-PSEntraIDGroup'
		'Enable-PSEntraIDGroupLicense'
		'Disable-PSEntraIDGroupLicense'
		'Enable-PSEntraIDGroupLicenseServicePlan'
		'Disable-PSEntraIDGroupLicenseServicePlan'
		'Get-PSEntraIDGroupMember'
		'Add-PSEntraIDGroupMember'
		'Remove-PSEntraIDGroupMember'
		'Add-PSEntraIDGroupOwner'
		'Remove-PSEntraIDGroupOwner'
		'Sync-PSEntraIDGroupMember'
		'Get-PSEntraIDAdministrativeUnit'
		'New-PSEntraIDAdministrativeUnit'
		'Set-PSEntraIDAdministrativeUnit'
		'Remove-PSEntraIDAdministrativeUnit'
		'Get-PSEntraIDAdministrativeUnitMember'
		'Add-PSEntraIDAdministrativeUnitMember'
		'Remove-PSEntraIDAdministrativeUnitMember'
		'Set-PSEntraIDCommandRetry'
		'Get-PSEntraIDCommandRetry'
	)

	# Cmdlets to export from this module
	CmdletsToExport    = @(
		'New-PSEntraIDBatchRequest'
	)

	# Variables to export from this module
	VariablesToExport  = @()

	# Aliases to export from this module
	AliasesToExport    = @()

	# List of all modules packaged with this module
	ModuleList         = @()

	# List of all files packaged with this module
	FileList           = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData        = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online
			# galleries. PSEdition_Core and the three OS tags are the ones the gallery
			# reads to drive its compatibility filters - without them the module is
			# absent from every filtered search, whatever CompatiblePSEditions says.
			Tags         = @(
				'Rest', 'Graph', 'MicrosoftGraph'
				'Azure', 'AzureActiveDirectory', 'MicrosoftEntra', 'MicrosoftEntraID'
				'Microsoft365', 'Licensing', 'Delta'
				'PSEdition_Core', 'Windows', 'Linux', 'MacOS'
			)

			# ExternalModuleDependencies deliberately absent. It means "this dependency
			# does not come from a gallery - do not install it", and PSFramework is the
			# only RequiredModule and does come from the gallery. Listing it there made
			# Install-Module skip PSFramework, so a first-time install produced a module
			# that could not import.

			# Both of these are rendered on the gallery listing page, so they have to
			# resolve for a stranger. They used to point at the Azure DevOps repository,
			# which is private - the development remote, not the published one. The
			# public face is the GitHub repository the Publish stage writes to.
			#
			# A URL to the license for this module.
			LicenseUri   = 'https://github.com/ondrejkracmar/PSMicrosoftEntraID/blob/main/LICENSE'

			# A URL to the main website for this project.
			ProjectUri   = 'https://github.com/ondrejkracmar/PSMicrosoftEntraID'

			# Served from the public GitHub mirror: vsts-publishToGitHub.ps1 copies docs/
			# wholesale (minus docs/internal/), so docs/icon.png rides along on every
			# release with no extra pipeline step. The URL must resolve for a stranger,
			# which rules out the private DevOps repository.
			IconUri      = 'https://raw.githubusercontent.com/ondrejkracmar/PSMicrosoftEntraID/main/docs/icon.png'

			# ReleaseNotes of this module
			ReleaseNotes = 'See changelog.md in the project repository.'

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}