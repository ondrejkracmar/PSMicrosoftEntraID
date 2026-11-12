function ConvertFrom-RestMachine {
	<#
	.SYNOPSIS
		Converts Defender for Endpoint machine objects to look nice.

	.DESCRIPTION
		Converts an MDE machines API response into
		PSMicrosoftEntraID.DefenderEndpoint.Machine through
		ConvertFrom-GraphResponse (GraphJson), like every other ConvertFrom-Rest*
		converter. Unknown members in the payload are ignored by the
		deserializer, so API additions never break the conversion; firstSeen
		and lastSeen become DateTime.

	.PARAMETER InputObject
		The rest response representing a machine.

	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Service 'PSMicrosoftEntraID.Endpoint' -Path machines -Method Get | ConvertFrom-RestMachine

		Turns the raw MDE payload into PSMicrosoftEntraID.DefenderEndpoint.Machine objects.
	#>
	[CmdletBinding()]
	param (
		$InputObject
	)
	if (-not $InputObject) { return }

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.DefenderEndpoint.Machine])
}
