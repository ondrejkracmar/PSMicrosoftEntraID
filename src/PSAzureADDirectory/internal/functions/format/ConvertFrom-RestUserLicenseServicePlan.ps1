function ConvertFrom-RestUserLicenseServicePlan {
	<#
	.SYNOPSIS
		Converts subscribed Sku service plans to look nice.

	.DESCRIPTION
		Converts subscribed Sku service plans to look nice.

	.PARAMETER InputObject
		The rest response representing a subscribed Sku
	
	.PARAMETER ServicePlan
		Add list of service plans of subscription to Azure AD user object into something userfriendly

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path subscribedSkus -Method Get -ErrorAction Stop | ConvertFrom-RestLicenseServicePlan
		
		Retrieves the specified subscribed Sku service plans and converts it into something userfriendly
		
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		[switch]$ServicePlan
	)

	begin {
		$subscribedSkuList = Get-PSFResultCache
	}

	process {
		if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.SkuId)) ) { return }
		if ($ServicePlan.IsPresent) {
			[PSCustomObject]@{
				PSTypeName           = 'PSAzureADDirectory.User.License.ServicePlan'
				SkuId                = $InputObject.skuId
				SkuPartNumber        = ($subscribedSkuList | Where-Object -Property SkuId -EQ -Value $InputObject.skuId).SkuPartNumber
				DisabledServicePlans = ($subscribedSkuList | Where-Object -Property SkuId -EQ -Value $InputObject.skuId).ServicePlans | Where-Object -Property servicePlanId -In -Value $InputObject.disabledPlans | Select-Object -Property ServicePlanId, ServicePlanName | ConvertFrom-RestServicePlan -User
				EnabledServicePlans  = ($subscribedSkuList | Where-Object -Property SkuId -EQ -Value $InputObject.skuId).ServicePlans | Where-Object -Property servicePlanId -NotIn -Value $InputObject.disabledPlans | Select-Object -Property ServicePlanId, ServicePlanName | ConvertFrom-RestServicePlan -User
			}
		}
		else {
			[PSCustomObject]@{
				PSTypeName    = 'PSAzureADDirectory.User.License'
				SkuId         = $InputObject.skuId
				SkuPartNumber = ($subscribedSkuList | Where-Object -Property SkuId -EQ -Value $InputObject.skuId).SkuPartNumber
			}
		}
	}
}