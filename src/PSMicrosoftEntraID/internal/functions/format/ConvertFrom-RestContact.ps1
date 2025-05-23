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
	$jsonString = $InputObject | ConvertTo-Json -Depth 4

	if ($InputObject -is [array]) {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Contacts.Contact[]])
	}
	else {
		[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
		[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
		[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Contacts.Contact])
	}
	return $serializer.ReadObject($stream)
}
