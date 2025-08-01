﻿function ConvertFrom-RestUserLicenseDetail {
    <#
	.SYNOPSIS
		Converts User Office 365 License Detail objects to look nice.

	.DESCRIPTION
		Converts User Office 365 License Detail objects to look nice.

	.PARAMETER InputObject
		The rest response representing a User Office 365 License Detail

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicenseDetail -InputObject (Invoke-RestRequest -Service 'graph' -Path pstnCalls -Method Get -ErrorAction Stop)
		Retrieves the specified User Office 365 License Detail and converts it into something userfriendly
	#>
    param (
        $InputObject
    )
    if (-not $InputObject) { return }

    $jsonString = $InputObject | ConvertTo-Json -Depth 3

    $type = if ($InputObject -is [array]) {
        [PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku[]]
    }
    else {
        [PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku]
    }

    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    $stream = [System.IO.MemoryStream]::new($byteArray)
    $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
    return $serializer.ReadObject($stream)
}