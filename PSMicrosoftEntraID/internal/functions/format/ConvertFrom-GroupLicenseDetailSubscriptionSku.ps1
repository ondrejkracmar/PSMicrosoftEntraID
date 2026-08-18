function ConvertFrom-GroupLicenseDetailSubscriptionSku {
    <#
    .SYNOPSIS
        Converts a group assigned license into a subscription SKU object.

    .DESCRIPTION
        Builds a PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku object from
        the group's assigned license and the subscribed SKU catalog, including service plan
        provisioning status.

    .PARAMETER LicenseDetail
        The assigned license details for a group.
    #>
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

    [hashtable] $seenServicePlanLookup = @{}

    [object[]] $servicePlans = @(
        foreach ($servicePlan in @($subscribedLicense.ServicePlans)) {
            if ($null -eq $servicePlan) {
                continue
            }

            [string] $servicePlanId = [string] $servicePlan.ServicePlanId
            [string] $servicePlanKey = $null
            if (-not [string]::IsNullOrWhiteSpace($servicePlanId)) {
                $servicePlanKey = $servicePlanId.ToLowerInvariant()
                $seenServicePlanLookup[$servicePlanKey] = $true
            }

            $servicePlanObject = [PSMicrosoftEntraID.Groups.LicenseManagement.ServicePlan]::new()
            $servicePlanObject.ServicePlanId = $servicePlanId
            $servicePlanObject.ServicePlanName = $servicePlan.ServicePlanName
            $servicePlanObject.ServicePlanFriendlyName = $servicePlan.ServicePlanFriendlyName
            $servicePlanObject.AppliesTo = $servicePlan.AppliesTo
            $servicePlanObject.ProvisioningStatus = if ($servicePlanKey -and $disabledPlanLookup.ContainsKey($servicePlanKey)) { 'Disabled' } else { 'Success' }
            $servicePlanObject
        }
    )

    foreach ($disabledPlanId in $disabledPlanLookup.Keys) {
        if ($seenServicePlanLookup.ContainsKey($disabledPlanId)) {
            continue
        }

        $servicePlanObject = [PSMicrosoftEntraID.Groups.LicenseManagement.ServicePlan]::new()
        $servicePlanObject.ServicePlanId = $disabledPlanId
        $servicePlanObject.ProvisioningStatus = 'Disabled'
        $servicePlanObject
    }

    $subscriptionSku = [PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku]::new()
    $subscriptionSku.Id = $subscribedLicense.SkuId
    $subscriptionSku.SkuId = $subscribedLicense.SkuId
    $subscriptionSku.SkuPartNumber = $subscribedLicense.SkuPartNumber
    $subscriptionSku.SkuFriendlyName = $subscribedLicense.SkuFriendlyName
    $subscriptionSku.ServicePlans = $servicePlans
    $subscriptionSku
}