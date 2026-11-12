function ConvertFrom-RestAdministrativeUnit {
	<#
	.SYNOPSIS
		Converts a REST API response object representing an administrative unit into a more user-friendly format.

	.DESCRIPTION
		Converts a REST API response object representing an administrative unit into a more user-friendly format.

	.PARAMETER InputObject
		The REST API response object that represents an administrative unit.

	.DESCRIPTION
		This function takes a REST API response object that represents an administrative unit and converts it into a more user-friendly format. This can be useful for displaying administrative unit information in a more readable way or for further processing.

	.EXAMPLE
		$adminUnit = Get-RestApiAdministrativeUnit -Id "adminUnitId"
		$formattedAdminUnit = ConvertFrom-RestAdministrativeUnit -InputObject $adminUnit
		Write-Output $formattedAdminUnit

	.EXAMPLE
		$adminUnits = Get-RestApiAdministrativeUnits
		$formattedAdminUnits = ConvertFrom-RestAdministrativeUnit -InputObject $adminUnits
		Write-Output $formattedAdminUnits
	#>
	param (
		$InputObject
	)

	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit])
}