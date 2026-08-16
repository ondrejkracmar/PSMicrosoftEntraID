function Export-PSEntraIDDeltaSession {
    <#
    .SYNOPSIS
        Saves a delta session to disk so the next run can carry on where this one stopped.

    .DESCRIPTION
        A delta session is a hashtable that lives only as long as the PowerShell session
        holding it. A scheduled task starts fresh every time, so without persisting the
        token it would re-read the whole tenant on every run and delta would buy nothing.

        Pairs with Import-PSEntraIDDeltaSession. Round-tripping by hand is the obvious
        alternative and gets it wrong: ConvertFrom-Json hands back a PSCustomObject, not
        a hashtable, and the delta parameter needs a hashtable.

        The file holds continuation tokens, not credentials. Treat it as you would any
        other state file - a stolen token still needs a valid connection to be used, but
        it does reveal which endpoints you track.

    .PARAMETER DeltaSession
        The delta session to save.

    .PARAMETER Path
        Where to write it. The parent directory must exist.

    .EXAMPLE
        PS C:\> Export-PSEntraIDDeltaSession -DeltaSession $delta -Path .\users.delta.json

        Saves the token so tomorrow's run asks only for what changed.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable] $DeltaSession,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter()]
        [switch] $EnableException,

        [Parameter()]
        [switch] $Force
    )

    begin {
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    }

    process {
        Invoke-PSFProtectedCommand -ActionString 'DeltaSession.Export' -ActionStringValues $Path -Target $Path -ScriptBlock {
            # Depth 5: a session is a flat map of uri -> @{ Token = '...' }, so this is
            # generous already, but ConvertTo-Json truncates silently at the default 2.
            $DeltaSession | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue
        if (Test-PSFFunctionInterrupt) { return }
    }

    end {}
}
