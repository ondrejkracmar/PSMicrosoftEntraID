function ConvertFrom-RestSubscribedSku {
	<#
	.SYNOPSIS
		Converts subscribed Sku objects to look nice.

	.DESCRIPTION
		Converts subscribed Sku objects to look nice.

	.PARAMETER InputObject
		The rest response representing a subscribed Sku

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path subscribedSkus -Method Get -ErrorAction Stop | ConvertFrom-RestSubscribedSku
		
		Retrieves the specified subscribed Sku and converts it into something userfriendly
		
	#>
	param (
		$InputObject
	)

	process {
		if (-not $InputObject) { return }
		$jsonString = $InputObject | ConvertTo-Json -Depth 3
		
		if ($InputObject -is [array]) {
			[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
			[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
			[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.License.SubscriptionSkuLicense[]])
		}
		else {
			[byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
			[System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
			[System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.License.SubscriptionSkuLicense])
		}
		return $serializer.ReadObject($stream)
	}
}


