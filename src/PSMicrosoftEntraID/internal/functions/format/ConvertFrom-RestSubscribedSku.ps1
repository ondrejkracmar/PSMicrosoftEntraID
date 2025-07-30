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

	if (-not $InputObject) { return }

	$jsonString = $InputObject | ConvertTo-Json -Depth 3

	$type = if ($InputObject -is [array]) {
		[PSMicrosoftEntraID.License.SubscriptionSkuLicense[]]
	}
	else {
		[PSMicrosoftEntraID.License.SubscriptionSkuLicense]
	}

	$byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
	$stream = [System.IO.MemoryStream]::new($byteArray)
	$serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
	return $serializer.ReadObject($stream)
}


