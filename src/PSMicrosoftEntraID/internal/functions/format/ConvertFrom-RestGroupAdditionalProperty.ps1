function ConvertFrom-RestGroupAdditionalProperty {
	<#
	.SYNOPSIS
		Converts additional group properties objects to look nice.

	.DESCRIPTION
		Converts additional group properties objects to look nice.

	.PARAMETER InputObject
		The rest response representing a additional group properties

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroupAdditionalProperty

		Retrieves the specified additional group properties and converts it into something userfriendly

	#>
	param (
		$InputObject
	)

	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Groups.GroupAdditionalProperty])
}