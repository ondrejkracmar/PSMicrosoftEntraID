function Invoke-EntraDeltaRequest {
    <#
    .SYNOPSIS
        Runs one Graph delta read and returns it as the typed delta objects for that
        resource.

    .DESCRIPTION
        Every Get-PSEntraID*Delta cmdlet does the same thing. Only two facts differ: the
        Graph path and the type to produce. Everything else - resolving the service,
        asserting the connection, reading the retry settings, deciding whether to pass a
        delta session through, the protected call and the conversion - was copied five
        times, so a fix to any of it had to be made five times or was made inconsistently.

        The five cmdlets still exist and are still the discoverable surface; what they no
        longer own is the machinery. Each is now its parameter block, its help, its path
        and its type.

        The distinction between "no delta session" and "a null delta session" is carried
        by parameter BINDING, not by value: the caller splats DeltaSession only when it
        was bound on the public cmdlet, and this function tests the same way. An omitted
        session means read everything without tracking a token; a bound one means track.

    .PARAMETER Cmdlet
        The $PSCmdlet of the calling public cmdlet. Failures are reported through it, so
        a user sees the command they typed rather than this helper.

    .PARAMETER Path
        The Graph delta endpoint, for example 'users/delta'.

    .PARAMETER TargetType
        The delta type to produce, for example [PSMicrosoftEntraID.Users.UserDelta].

    .PARAMETER DeltaSession
        Hashtable holding the delta token. Pass it only when the caller bound it.

    .PARAMETER MinimalDelta
        Ask Graph for only the changed properties plus the identifier.

    .PARAMETER EnableException
        Throw on failure instead of writing a warning.

    .EXAMPLE
        PS C:\> Invoke-EntraDeltaRequest -Cmdlet $PSCmdlet -Path 'users/delta' -TargetType ([PSMicrosoftEntraID.Users.UserDelta])

        Reads every user, tracking nothing.

    .EXAMPLE
        PS C:\> Invoke-EntraDeltaRequest -Cmdlet $PSCmdlet -Path 'groups/delta' -TargetType ([PSMicrosoftEntraID.Groups.GroupDelta]) -DeltaSession $session -MinimalDelta

        Reads what changed since the token in $session, minimally, and writes the new
        token back into the same hashtable.

    .NOTES
        Internal helper behind the five delta cmdlets.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [type] $TargetType,

        [Parameter()]
        [AllowNull()]
        [hashtable] $DeltaSession,

        [Parameter()]
        [switch] $MinimalDelta,

        [Parameter()]
        [switch] $EnableException
    )

    [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
    Assert-EntraConnection -Service $service -Cmdlet $Cmdlet
    [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
    [TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))

    $requestParameters = @{
        Service     = $service
        Path        = $Path
        Method      = 'Get'
        ErrorAction = 'Stop'
    }
    # Only pass the delta parameters when asked for, so an omitted session reads
    # everything instead of tracking a token nobody wants.
    if ($PSBoundParameters.ContainsKey('DeltaSession')) { $requestParameters['DeltaSession'] = $DeltaSession }
    if ($MinimalDelta.IsPresent) { $requestParameters['MinimalDelta'] = $true }

    $result = Invoke-PSFProtectedCommand -ActionString 'Delta.Get' -ActionStringValues $Path `
        -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
        ConvertFrom-RestDelta -InputObject (Invoke-EntraRequest @requestParameters) -TargetType $TargetType
    } -EnableException:$EnableException -PSCmdlet $Cmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
    if (Test-PSFFunctionInterrupt) { return }
    $result
}
