function Resolve-PSEntraIDConfirmPreference {
    <#
    .SYNOPSIS
        Resolves the effective confirmation preference for a PSEntraID cmdlet.

    .DESCRIPTION
        Evaluates the caller's Force/Confirm intent and returns the effective
        boolean confirmation state that Invoke-PSFProtectedCommand's -Confirm
        parameter should be bound to.

        Rules:
        - If -Confirm was explicitly bound (regardless of value), honor it.
        - Else, if -Force was supplied, suppress confirmation.
        - Else, return $true so the built-in ConfirmPreference/ConfirmImpact
          logic applies.

    .PARAMETER BoundParameters
        The caller's $PSBoundParameters dictionary. Required to detect whether
        -Confirm was explicitly provided (including -Confirm:$false).

    .PARAMETER Force
        The caller's -Force switch.

    .PARAMETER Confirm
        The caller's -Confirm switch value. Only considered when -Confirm was
        explicitly bound (see BoundParameters).

    .EXAMPLE
        PS C:\> $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSupportsShouldProcess', '', Justification = 'The -Confirm parameter is a value-passthrough for callers; this function does not perform ShouldProcess itself.')]
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $BoundParameters,

        [switch] $Force,

        [switch] $Confirm
    )

    if ($BoundParameters.ContainsKey('Confirm')) {
        return [bool] $Confirm
    }
    if ($Force.IsPresent) {
        return $false
    }
    return $true
}
