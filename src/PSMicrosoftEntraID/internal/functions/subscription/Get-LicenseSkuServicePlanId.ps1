function Get-LicenseSkuServicePlanId {
    <#
    .SYNOPSIS
        Returns every service plan id of a subscribed SKU, or stops the calling cmdlet.

    .DESCRIPTION
        Enable-*LicenseServicePlan assigns a SKU a target does not hold yet with every plan
        disabled except the requested ones, and "every plan" is this list. An empty list
        there does not mean "nothing to disable" - it means the licence goes out with every
        plan enabled. So neither a failed catalog read nor an empty plan list may pass:
        both terminate the CALLING cmdlet before it writes anything.

        The catalog read used to run non-terminating: a throttled or failed read only
        warned, the list came back empty, and the licence was assigned with every plan on.

    .PARAMETER Cmdlet
        The calling cmdlet ($PSCmdlet); a failure terminates it.

    .PARAMETER SkuId
        The SKU whose service plans are returned.

    .PARAMETER SkuTarget
        The SKU as the caller named it (id or part number), for the error message.

    .PARAMETER SubscribedSku
        The subscribed SKU catalog the caller has already read. Without it the catalog is
        read here, with Get-PSEntraIDSubscribedLicense, and a failed read terminates.

    .EXAMPLE
        PS C:\> [string[]] $allServicePlanId = @(Get-LicenseSkuServicePlanId -Cmdlet $PSCmdlet -SkuId $bodySkuId -SkuTarget $skuTarget)

        Returns the service plan ids of the SKU, or stops the caller.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet] $Cmdlet,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SkuId,
        [string] $SkuTarget,
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $SubscribedSku
    )

    if ([string]::IsNullOrWhiteSpace($SkuTarget)) { $SkuTarget = $SkuId }
    if (-not $PSBoundParameters.ContainsKey('SubscribedSku')) {
        try {
            # -EnableException: the read reports a failure by throwing, not by a warning
            # and an empty result that reads the same as "no plans".
            [object[]] $SubscribedSku = @(Get-PSEntraIDSubscribedLicense -EnableException -ErrorAction Stop)
        }
        catch {
            Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name LicenseServicePlan.Catalog.Failed) -f $SkuTarget) -ErrorRecord $_
        }
    }

    [string[]] $servicePlanIdList = @($SubscribedSku |
        Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace($SkuId) -and ([string] $_.SkuId) -eq $SkuId } |
        ForEach-Object { $_.ServicePlans } |
        Where-Object { $null -ne $_ } |
        ForEach-Object { [string] $_.ServicePlanId } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($servicePlanIdList.Count -eq 0) {
        Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name LicenseServicePlan.Catalog.Empty) -f $SkuTarget)
    }
    [string[]] $servicePlanIdList
}
