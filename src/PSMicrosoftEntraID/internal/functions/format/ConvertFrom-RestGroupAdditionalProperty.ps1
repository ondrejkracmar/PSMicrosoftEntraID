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
	$jsonString = $InputObject | ConvertTo-Json -Depth 3

	if ($InputObject -is [array]) {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Groups.GroupAdditionalProperty[]])
	}
	else {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Groups.GroupAdditionalProperty])
	}
	return $serializer.ReadObject($stream)
}