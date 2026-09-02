function ConvertFrom-RestMachine {
	<#
	.SYNOPSIS
		Converts Defender for Endpoint machine objects to look nice.

	.DESCRIPTION
		Converts an MDE machines API response into
		PSMicrosoftEntraID.DefenderEndpoint.Machine via the same
		DataContractJsonSerializer round-trip every other ConvertFrom-Rest*
		converter uses. Unknown members in the payload are ignored by the
		serializer, so API additions never break the conversion.

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

	$jsonString = $InputObject | ConvertTo-Json -Depth 4

	$type = if ($InputObject -is [array]) {
		[PSMicrosoftEntraID.DefenderEndpoint.Machine[]]
	}
	else {
		[PSMicrosoftEntraID.DefenderEndpoint.Machine]
	}

	$byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	$stream = [System.IO.MemoryStream]::new($byteArray)
	$serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
	return $serializer.ReadObject($stream)
}
