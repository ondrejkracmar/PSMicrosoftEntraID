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

	$jsonString = $InputObject | ConvertTo-Json -Depth 4

	$type = if ($InputObject -is [array]) {
		[PSMicrosoftEntraID.Users.User[]]
	}
	else {
		[PSMicrosoftEntraID.Users.User]
	}

	$byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	$stream = [System.IO.MemoryStream]::new($byteArray)
	$serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
	return $serializer.ReadObject($stream)
}
