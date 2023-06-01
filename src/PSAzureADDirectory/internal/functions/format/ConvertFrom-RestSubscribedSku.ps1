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
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)

	process {
		if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.id)) ) { return }
		[PSCustomObject]@{
			PSTypeName    = 'PSAzureADDirectory.License'
			Id            = $InputObject.id
			SkuId         = $InputObject.skuId
			SkuPartNumber = $InputObject.skuPartNumber
			AppliesTo     = $InputObject.appliesTo
			ConsumedUnits = $InputObject.consumedUnits
			PrepaidUnits  = $InputObject.prepaidUnits
			ServicePlans  = $InputObject.servicePlans
		}
	}
}