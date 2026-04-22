function ConvertFrom-RestGroupLicenseDetail {
    <#
	.SYNOPSIS
		Converts Group Office 365 License Detail objects to look nice.

	.DESCRIPTION
		Converts Group Office 365 License Detail objects to look nice.

	.PARAMETER InputObject
		The rest response representing a Group Office 365 License Detail

	.EXAMPLE
		PS C:\> Get-PSEntraIDGroupLicenseDetail -InputObject (Invoke-RestRequest -Service 'graph' -Path groups -Method Get -ErrorAction Stop)
		Retrieves the specified Group Office 365 License Detail and converts it into something userfriendly
	#>
    param (
        $InputObject
    )
    if (-not $InputObject) { return }

    $jsonString = $InputObject | ConvertTo-Json -Depth 3

    $type = if ($InputObject -is [array]) {
        [PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku[]]
    }
    else {
        [PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku]
    }

    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    $stream = [System.IO.MemoryStream]::new($byteArray)
    $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
    return $serializer.ReadObject($stream)
}