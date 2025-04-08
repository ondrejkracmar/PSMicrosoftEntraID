function ConvertFrom-RestGroup {
	<#
	.SYNOPSIS
		Converts a REST API response object representing a group into a more user-friendly format.
	
	.DESCRIPTION
		Converts a REST API response object representing a group into a more user-friendly format.

	.PARAMETER InputObject
		The REST API response object that represents a group.

	.DESCRIPTION
		This function takes a REST API response object that represents a group and converts it into a more user-friendly format. This can be useful for displaying group information in a more readable way or for further processing.

	.EXAMPLE
		$group = Get-RestApiGroup -Id "groupId"
		$formattedGroup = ConvertFrom-RestGroup -InputObject $group
		Write-Output $formattedGroup
	#>
	param (
		$InputObject
	)
	
	if (-not $InputObject) { return }
	$jsonString = $InputObject | ConvertTo-Json -Depth 3
	
	if ($InputObject -is [array]) {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Groups.Group[]])
	}
	else {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Groups.Group])
	}
	return $serializer.ReadObject($stream)
}