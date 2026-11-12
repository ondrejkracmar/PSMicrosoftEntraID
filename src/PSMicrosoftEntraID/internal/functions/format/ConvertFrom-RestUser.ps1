function ConvertFrom-RestUser {
	<#
	.SYNOPSIS
		Converts user objects to look nice.

	.DESCRIPTION
		Converts user objects to look nice.

	.PARAMETER InputObject
		The rest response representing a user

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestUser

		Retrieves the specified user and converts it into something userfriendly

	#>
	[CmdletBinding()]
	param (
		$InputObject
	)
	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Users.User])
}
