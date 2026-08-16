function ConvertFrom-RestDevice {
	<#
	.SYNOPSIS
		Converts device objects to look nice.

	.DESCRIPTION
		Converts a Graph device response into PSMicrosoftEntraID.Devices.Device.

		Get-PSEntraIDDevice used to stamp the type NAME onto a raw PSCustomObject with
		PSObject.TypeNames - a valid PowerShell pattern, but the odd one out here: every
		other resource in this module comes back as a real .NET type. Now that
		DeviceDelta has to derive from an actual Device class, both cmdlets return the
		same type instead of two things that merely share a name.

	.PARAMETER InputObject
		The rest response representing a device.

	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Service 'graph' -Path devices -Method Get | ConvertFrom-RestDevice

		Turns the raw Graph payload into PSMicrosoftEntraID.Devices.Device objects.
	#>
	[CmdletBinding()]
	param (
		$InputObject
	)
	if (-not $InputObject) { return }

	$jsonString = $InputObject | ConvertTo-Json -Depth 4

	$type = if ($InputObject -is [array]) {
		[PSMicrosoftEntraID.Devices.Device[]]
	}
	else {
		[PSMicrosoftEntraID.Devices.Device]
	}

	$byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	$stream = [System.IO.MemoryStream]::new($byteArray)
	$serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
	return $serializer.ReadObject($stream)
}
