function Import-PSEntraIDDeltaSession {
    <#
    .SYNOPSIS
        Loads a delta session saved by Export-PSEntraIDDeltaSession.

    .DESCRIPTION
        Returns a hashtable ready to hand to a delta cmdlet's -DeltaSession parameter.

        A missing file is not an error: the first run of a scheduled task has nothing to
        load, and an empty session is exactly what a first run needs. That keeps the
        calling script to three lines with no existence check.

        Doing this by hand is the trap this exists for. ConvertFrom-Json returns a
        PSCustomObject, and -DeltaSession takes a hashtable, so the obvious round-trip
        fails at the point of use rather than at the point of the mistake.

    .PARAMETER Path
        The file written by Export-PSEntraIDDeltaSession.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .EXAMPLE
        PS C:\> $delta = Import-PSEntraIDDeltaSession -Path .\users.delta.json
        PS C:\> Get-PSEntraIDUserDelta -DeltaSession $delta
        PS C:\> Export-PSEntraIDDeltaSession -DeltaSession $delta -Path .\users.delta.json

        The whole scheduled-task pattern: load, ask for changes, save.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter()]
        [switch] $EnableException
    )

    process {
        if (-not (Test-Path -LiteralPath $Path)) {
            # First run. An empty session means "read everything and start tracking".
            Write-PSFMessage -Level Verbose -String 'DeltaSession.NotFound' -StringValues $Path
            return @{}
        }

        $result = Invoke-PSFProtectedCommand -ActionString 'DeltaSession.Import' -ActionStringValues $Path -Target $Path -ScriptBlock {
            $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $session = @{}
            foreach ($property in $raw.PSObject.Properties) {
                # Each entry is itself an object; -DeltaSession indexes into it with
                # .Token, so it has to come back as a hashtable too.
                $entry = @{}
                foreach ($inner in $property.Value.PSObject.Properties) { $entry[$inner.Name] = $inner.Value }
                $session[$property.Name] = $entry
            }
            $session
        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -WhatIf:$false
        if (Test-PSFFunctionInterrupt) { return }

        if ($null -eq $result) { return @{} }
        $result
    }
}
