function Clear-PipelineBoundParameter {
    <#
    .SYNOPSIS
        Drops the parameters a pipeline record bound, so the next record starts clean.

    .DESCRIPTION
        With ValueFromPipelineByPropertyName, PowerShell resets a parameter VARIABLE to its
        default before binding the next pipeline record, but it does NOT remove the key
        from $PSBoundParameters. A key bound by record 1 therefore stays in the dictionary
        while record 2 runs, and every "if ($PSBoundParameters.ContainsKey('X'))" in process
        answers yes for a property record 2 does not even have - and writes the reset
        default. Piping {Id; AccountEnabled = $true; Department = 'IT'} and then
        {Id; JobTitle = 'Dev'} into Set-PSEntraIDUser sent
        {"department":"","accountEnabled":false,"jobTitle":"Dev"} for the second user.

        The caller snapshots the keys bound on the command line in begin (they are all
        known there) and calls this in a finally around its process body. Everything not in
        the snapshot was bound by the record just processed and is removed; the binder adds
        back exactly what the next record carries. $PSBoundParameters then means "bound for
        THIS record" on every process call.

        The dictionary is the live object PowerShell binds into (it is also
        $PSCmdlet.MyInvocation.BoundParameters), so it is modified in place.

    .PARAMETER BoundParameters
        The caller's $PSBoundParameters.

    .PARAMETER CommandLineParameter
        The keys of $PSBoundParameters captured in the caller's begin block.

    .EXAMPLE
        PS C:\> begin { [string[]] $commandLineParameter = @($PSBoundParameters.Keys) }
        PS C:\> process { try { ... } finally { Clear-PipelineBoundParameter -BoundParameters $PSBoundParameters -CommandLineParameter $commandLineParameter } }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary] $BoundParameters,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $CommandLineParameter
    )

    foreach ($key in @($BoundParameters.Keys)) {
        if ($key -notin $CommandLineParameter) {
            [void] $BoundParameters.Remove($key)
        }
    }
}
