function ConvertFrom-RestUserSubscribedSku {
    <#
	.SYNOPSIS
		Converts license objects to look nice.

	.DESCRIPTION
		Converts license objects to look nice.

	.PARAMETER InputObject
		The rest response representing a license
    
    .PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestLicense
		
        Retrieves the specified license and converts it into something userfriendly
        
	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$SkuId
    )
    begin {

    }
    process {
        $assignedLicenses = ($InputObject.assignedLicenses | ConvertFrom-RestUserLicenseServicePlan -ServicePlan) | Where-Object -Property skuId -Value $SkuId -EQ
        if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.id)) -or (([object]::Equals($null, ($assignedLicenses))))) { return }
        [PSCustomObject]@{
            PSTypeName           = 'PSMicrosoftEntraID.User.SubscribedSku'
            Id                   = $InputObject.id
            UserPrincipalName    = $InputObject.userPrincipalName
            UserType             = $InputObject.userType
            AccountEnabled       = $InputObject.accountEnabled
            DisplayName          = $InputObject.displayName
            Mail                 = $InputObject.mail
            UsageLocation        = $InputObject.usageLocation
            CompanyName          = $InputObject.companyName
            SkuId                = $assignedLicenses.SkuId
            SkuPartNumber        = $assignedLicenses.SkuPartNumber
            DisabledServicePlans = [string[]]$assignedLicenses.DisabledServicePlans.ServicePlanName
            EnabledServicePlans  = [string[]]$assignedLicenses.EnabledServicePlans.ServicePlanName
        }
    }
}