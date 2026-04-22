function Update-PSEntraIDSubscribedLicenseDisplayName {
    [OutputType([System.Object[]])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal helper that decorates pipeline objects in place; no remote state change.')]
    [CmdletBinding()]
    param (
        [object[]] $InputObject
    )

    if ($null -eq $InputObject -or $InputObject.Count -eq 0) {
        return $InputObject
    }

    [object[]] $licenseIdentifiers = @(Get-PSEntraIDLicenseIdentifier)
    if ($licenseIdentifiers.Count -eq 0) {
        return $InputObject
    }

    [hashtable] $licenseIdentifiersBySkuId = @{}
    foreach ($licenseIdentifier in $licenseIdentifiers) {
        if (-not [string]::IsNullOrWhiteSpace($licenseIdentifier.SkuId)) {
            $licenseIdentifiersBySkuId[$licenseIdentifier.SkuId.ToLowerInvariant()] = $licenseIdentifier
        }
    }

    foreach ($subscribedLicense in $InputObject) {
        if ($null -eq $subscribedLicense) {
            continue
        }

        [object] $licenseIdentifier = $null
        if (-not [string]::IsNullOrWhiteSpace($subscribedLicense.SkuId)) {
            [string] $skuKey = $subscribedLicense.SkuId.ToLowerInvariant()
            if ($licenseIdentifiersBySkuId.ContainsKey($skuKey)) {
                $licenseIdentifier = $licenseIdentifiersBySkuId[$skuKey]
            }
        }

        [string] $skuFriendlyName = if ($licenseIdentifier) { $licenseIdentifier.SkuFriendlyName } else { $null }
        Add-Member -InputObject $subscribedLicense -MemberType NoteProperty -Name 'SkuFriendlyName' -Value $skuFriendlyName -Force

        if ($null -eq $subscribedLicense.ServicePlans) {
            continue
        }

        [hashtable] $servicePlansById = @{}
        if ($licenseIdentifier -and $licenseIdentifier.ServicePlans) {
            foreach ($servicePlanIdentifier in $licenseIdentifier.ServicePlans) {
                if (-not [string]::IsNullOrWhiteSpace($servicePlanIdentifier.ServicePlanId)) {
                    $servicePlansById[$servicePlanIdentifier.ServicePlanId.ToLowerInvariant()] = $servicePlanIdentifier
                }
            }
        }

        foreach ($servicePlan in $subscribedLicense.ServicePlans) {
            if ($null -eq $servicePlan) {
                continue
            }

            [string] $servicePlanFriendlyName = $null
            if (-not [string]::IsNullOrWhiteSpace($servicePlan.ServicePlanId)) {
                [string] $servicePlanKey = $servicePlan.ServicePlanId.ToLowerInvariant()
                if ($servicePlansById.ContainsKey($servicePlanKey)) {
                    $servicePlanFriendlyName = $servicePlansById[$servicePlanKey].ServicePlanFriendlyName
                }
            }

            Add-Member -InputObject $servicePlan -MemberType NoteProperty -Name 'ServicePlanFriendlyName' -Value $servicePlanFriendlyName -Force
        }
    }

    return $InputObject
}