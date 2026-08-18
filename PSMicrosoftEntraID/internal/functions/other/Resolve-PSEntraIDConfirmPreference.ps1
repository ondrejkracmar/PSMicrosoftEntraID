function Resolve-PSEntraIDConfirmPreference {
    <#
    .SYNOPSIS
        Resolves the effective confirmation preference for a PSEntraID cmdlet.

    .DESCRIPTION
        Evaluates the caller's Force/Confirm intent and returns a hashtable to SPLAT
        onto Invoke-PSFProtectedCommand.

        Rules:
        - If -Confirm was explicitly bound (regardless of value), honor it.
        - Else, if -Force was supplied, suppress confirmation.
        - Else, return an EMPTY hashtable so -Confirm is not bound at all, leaving the
          decision to ConfirmImpact and ConfirmPreference.

        The last case is why this returns a splat and not a bool. Binding -Confirm:$true
        does not mean "apply the usual rules" - it FORCES a prompt whatever the
        ConfirmImpact is. Verified with a Medium-impact command under the default
        ConfirmPreference of High: unbound -Confirm runs silently, -Confirm:$true
        prompts. Returning $true here therefore made every cmdlet prompt unless the
        caller passed -Force or -Confirm:$false - the opposite of what the comment
        claimed.

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
        PS C:\> Invoke-PSFProtectedCommand -ActionString 'Some.Action' -ScriptBlock { } @cmdLetConfirm
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSupportsShouldProcess', '', Justification = 'The -Confirm parameter is a value-passthrough for callers; this function does not perform ShouldProcess itself.')]
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $BoundParameters,

        [switch] $Force,

        [switch] $Confirm
    )

    if ($BoundParameters.ContainsKey('Confirm')) {
        return @{ Confirm = [bool] $Confirm }
    }
    if ($Force.IsPresent) {
        return @{ Confirm = $false }
    }
    return @{}
}
