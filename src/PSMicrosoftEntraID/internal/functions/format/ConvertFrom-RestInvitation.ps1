function ConvertFrom-RestInvitation {
	<#
	.SYNOPSIS
		Converts a REST API response object representing an invitation into a more user-friendly format.

	.DESCRIPTION
		Converts a REST API response object representing an invitation into a more user-friendly format.

	.PARAMETER InputObject
		The REST API response object that represents an invitation.

	.DESCRIPTION
		This function takes a REST API response object that represents an invitation and converts it into a more user-friendly format. This can be useful for displaying invitation information in a more readable way or for further processing.

	.EXAMPLE
		$invitation = Get-RestApiInvitation -Id "invitationId"
		$formattedInvitation = ConvertFrom-RestInvitation -InputObject $invitation
		Write-Output $formattedInvitation

	.EXAMPLE
		$invitations = Get-RestApiInvitations
		$formattedInvitations = ConvertFrom-RestInvitation -InputObject $invitations
		Write-Output $formattedInvitations
	#>
	param (
		$InputObject
	)

	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Users.Invitations.Invitation])
}