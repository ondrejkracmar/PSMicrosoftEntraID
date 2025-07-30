function ConvertFrom-RestOrganizationDetail {
	<#
	.SYNOPSIS
		Converts user objects to look nice.

	.DESCRIPTION
		Converts user objects to look nice.

	.PARAMETER InputObject
		The rest response representing a user

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path 'admin/serviceAnnouncement/messages' -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationDetail

		Retrieves the specified user and converts it into something userfriendly

	#>
	param (
		$InputObject
	)
	if (-not $InputObject) { return }

	$jsonString = $InputObject | ConvertTo-Json -Depth 4

	$type = if ($InputObject -is [array]) {
		[PSMicrosoftEntraID.Organization.OrganizationDetail[]]
	}
	else {
		[PSMicrosoftEntraID.Organization.OrganizationDetail]
	}

	$byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	$stream = [System.IO.MemoryStream]::new($byteArray)
	$serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
	return $serializer.ReadObject($stream)

}
