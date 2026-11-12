function ConvertFrom-RestContact {
	<#
	.SYNOPSIS
		Converts user objects to look nice.

	.DESCRIPTION
		Converts user objects to look nice.

	.PARAMETER InputObject
		The rest response representing a user

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestContact

		Retrieves the specified user and converts it into something userfriendly

	#>
	param (
		$InputObject
	)
	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Contacts.Contact])
}
