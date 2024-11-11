function ConvertFrom-RestUserLicenseDetail {
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
    [CmdletBinding()]
    param (
        $InputObject
    )

    process {
        if (-not $InputObject) { return }
        $jsonString = $InputObject | ConvertTo-Json -Depth 3

        if ($InputObject -is [array]) {
            [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
            [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
            [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku[]])
        }
        else {
            [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
            [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
            [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku])
        }
        return $serializer.ReadObject($stream)
    }

}