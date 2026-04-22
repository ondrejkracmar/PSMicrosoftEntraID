function ConvertFrom-GroupLicenseDetailSubscriptionSku {
    param (
        [Parameter(Mandatory = $true)]
        $LicenseDetail
    )

    [object[]] $subscribedLicenses = @(Get-PSEntraIDSubscribedLicense)
    if ($subscribedLicenses.Count -eq 0) {
        return
    }

    [string] $skuId = [string] $LicenseDetail.SkuId
    [object] $subscribedLicense = $subscribedLicenses |
        Where-Object { ([string] $PSItem.SkuId) -eq $skuId } |
        Select-Object -First 1

    if ([object]::Equals($subscribedLicense, $null)) {
        return
    }

    [hashtable] $disabledPlanLookup = @{}
    foreach ($disabledPlan in @($LicenseDetail.DisabledPlans)) {
        if ($null -eq $disabledPlan) {
            continue
        }

        [string] $disabledPlanId = [string] $disabledPlan
        if (-not [string]::IsNullOrWhiteSpace($disabledPlanId)) {
            $disabledPlanLookup[$disabledPlanId.ToLowerInvariant()] = $true
        }
    }

    [object[]] $servicePlans = @(
        foreach ($servicePlan in @($subscribedLicense.ServicePlans)) {
            if ($null -eq $servicePlan) {
                continue
            }

            [string] $servicePlanId = [string] $servicePlan.ServicePlanId
            if (-not [string]::IsNullOrWhiteSpace($servicePlanId) -and $disabledPlanLookup.ContainsKey($servicePlanId.ToLowerInvariant())) {
                continue
            }

            $servicePlanObject = [PSMicrosoftEntraID.Groups.LicenseManagement.ServicePlan]::new()
            $servicePlanObject.ServicePlanId = $servicePlanId
            $servicePlanObject.ServicePlanName = $servicePlan.ServicePlanName
            $servicePlanObject.ServicePlanFriendlyName = $servicePlan.ServicePlanFriendlyName
            $servicePlanObject.AppliesTo = $servicePlan.AppliesTo
            $servicePlanObject
        }
    )

    $subscriptionSku = [PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku]::new()
    $subscriptionSku.Id = $subscribedLicense.SkuId
    $subscriptionSku.SkuId = $subscribedLicense.SkuId
    $subscriptionSku.SkuPartNumber = $subscribedLicense.SkuPartNumber
    $subscriptionSku.SkuFriendlyName = $subscribedLicense.SkuFriendlyName
    $subscriptionSku.ServicePlans = $servicePlans
    $subscriptionSku
}