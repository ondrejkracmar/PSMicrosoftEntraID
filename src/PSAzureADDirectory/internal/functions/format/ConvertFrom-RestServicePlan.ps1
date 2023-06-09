function ConvertFrom-RestServicePlan {
    <#
	.SYNOPSIS
		Converts subscribed Sku service plans to look nice.

	.DESCRIPTION
		Converts subscribed Sku service plans to look nice.

	.PARAMETER InputObject
		The rest response representing a subscribed Sku
    
    .PARAMETER User
        Coverts for user object

	.EXAMPLE
		Invoke-RestRequest -Service 'graph' -Path subscribedSkus -Method Get -ErrorAction Stop | ConvertFrom-RestLicenseServicePlan
        
        Retrieves the specified subscribed ServicePlan and converts it into something userfriendly
        
	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [switch] $User
    )

    process {
        if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.servicePlanId)) ) { return }
        if ($User.IsPresent) {
            [PSCustomObject]@{
                PSTypeName      = 'PSAzureADDirectory.License.ServicePlan'
                ServicePlanId   = $InputObject.servicePlanId
                ServicePlanName = $InputObject.servicePlanName
            }
        }
        else {
            [PSCustomObject]@{
                PSTypeName         = 'PSAzureADDirectory.License.ServicePlan'
                ServicePlanId      = $InputObject.servicePlanId
                ServicePlanName    = $InputObject.servicePlanName
                ProvisioningStatus = $InputObject.provisioningStatus
                AppliesTo          = $InputObject.appliesTo
            }
        }
    }
}