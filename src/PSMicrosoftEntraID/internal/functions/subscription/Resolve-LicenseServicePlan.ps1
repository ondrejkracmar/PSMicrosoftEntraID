function Resolve-LicenseServicePlan {
    <#
    .SYNOPSIS
        Resolves the SKU and the service plans a service-plan cmdlet was asked for, or stops that cmdlet.

    .DESCRIPTION
        Resolves -SkuId or -SkuPartNumber and -ServicePlanId or -ServicePlanName against the
        subscribed SKU catalog the calling cmdlet has already read.

        Anything that does not resolve terminates the CALLING cmdlet. A plan name with a
        typo used to drop out of the list without a word; for a target that does not hold
        the SKU yet, Enable-* starts from "every plan disabled" and enables the requested
        plans - so a typo assigned the licence with every plan disabled, a licence consumed
        for nothing. An unknown -SkuPartNumber went the same way with an empty skuId.

    .PARAMETER Cmdlet
        The calling cmdlet ($PSCmdlet); a failure terminates it.

    .PARAMETER SubscribedSku
        The subscribed SKUs of the tenant, as Get-PSEntraIDSubscribedSku or
        Get-PSEntraIDSubscribedLicense return them.

    .PARAMETER SkuId
        The SKU by id.

    .PARAMETER SkuPartNumber
        The SKU by part number.

    .PARAMETER ServicePlanId
        The requested service plans by id.

    .PARAMETER ServicePlanName
        The requested service plans by name.

    .EXAMPLE
        PS C:\> $resolved = Resolve-LicenseServicePlan -Cmdlet $PSCmdlet -SubscribedSku $subscribedSkus -SkuPartNumber ENTERPRISEPACK -ServicePlanName EXCHANGE_S_ENTERPRISE

        Returns the SKU id, the plan ids and the display targets, or stops the caller.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet] $Cmdlet,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $SubscribedSku,
        [string] $SkuId,
        [string] $SkuPartNumber,
        [string[]] $ServicePlanId,
        [string[]] $ServicePlanName
    )

    if ($PSBoundParameters.ContainsKey('SkuId')) {
        [string] $skuTarget = $SkuId
        [string] $bodySkuId = $SkuId
        $matchedSku = @($SubscribedSku | Where-Object { $null -ne $_ -and ([string] $_.SkuId) -eq $SkuId })[0]
        if ([object]::Equals($matchedSku, $null)) {
            Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $SkuId)
        }
    }
    else {
        [string] $skuTarget = $SkuPartNumber
        $matchedSku = @($SubscribedSku | Where-Object { $null -ne $_ -and $_.SkuPartNumber -eq $SkuPartNumber })[0]
        if ([object]::Equals($matchedSku, $null)) {
            Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.SkuPartNumber.NotFound) -f $SkuPartNumber)
        }
        [string] $bodySkuId = $matchedSku.SkuId
    }

    $skuServicePlans = @($matchedSku.ServicePlans | Where-Object { $null -ne $_ })
    [string[]] $allServicePlanId = @($skuServicePlans | ForEach-Object { [string] $_.ServicePlanId })
    if ($PSBoundParameters.ContainsKey('ServicePlanId')) {
        [string] $servicePlanTarget = ($ServicePlanId | ForEach-Object { "'{0}'" -f $_ }) -join ','
        [string[]] $missingServicePlan = @($ServicePlanId | Where-Object { $allServicePlanId -notcontains $_ })
        [string[]] $resolvedServicePlanId = @($ServicePlanId)
    }
    else {
        [string] $servicePlanTarget = ($ServicePlanName | ForEach-Object { "'{0}'" -f $_ }) -join ','
        [string[]] $knownServicePlanName = @($skuServicePlans | ForEach-Object { [string] $_.ServicePlanName })
        [string[]] $missingServicePlan = @($ServicePlanName | Where-Object { $knownServicePlanName -notcontains $_ })
        [string[]] $resolvedServicePlanId = @($skuServicePlans | Where-Object { $ServicePlanName -contains $_.ServicePlanName } | ForEach-Object { [string] $_.ServicePlanId })
    }
    if ($missingServicePlan.Count -gt 0) {
        Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name LicenseServicePlan.NotFound) -f (($missingServicePlan | ForEach-Object { "'{0}'" -f $_ }) -join ','), $skuTarget)
    }

    @{
        SkuId             = $bodySkuId
        SkuTarget         = $skuTarget
        ServicePlanId     = $resolvedServicePlanId
        ServicePlanTarget = $servicePlanTarget
        AllServicePlanId  = $allServicePlanId
    }
}
