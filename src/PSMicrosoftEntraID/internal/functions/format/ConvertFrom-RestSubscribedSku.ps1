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

	ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.License.SubscriptionSkuLicense])
}


