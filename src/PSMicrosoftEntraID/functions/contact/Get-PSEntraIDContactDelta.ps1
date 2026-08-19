function Get-PSEntraIDContactDelta {
    <#
    .SYNOPSIS
        Retrieves only the contacts that changed since the previous call.

    .DESCRIPTION
        Wraps Graph's contacts/delta endpoint. The first call with a given delta session
        returns everything and stores a token in it; every call after that returns only
        what changed since - created, updated, or removed.

        This is the cheap way to stay current. Re-reading a tenant of tens of thousands
        of objects to find the handful that moved costs the same every time; a delta call
        costs what actually changed.

        Removed objects come back too, with ChangeType set to Deleted or Purged and
        little more than their id populated - Graph does not resend the rest of something
        that is gone. That is the point: a full read cannot tell you what disappeared.

        The delta session is a plain hashtable that lives only as long as your session.
        For a scheduled task, persist it between runs with
        Export-PSEntraIDDeltaSession and Import-PSEntraIDDeltaSession.

    .PARAMETER DeltaSession
        Hashtable holding the delta token. Pass an empty one on the first call and the
        same one afterwards. Omit it entirely to read everything without tracking.

    .PARAMETER MinimalDelta
        Return only the properties that changed, plus the identifier, instead of the
        whole object. Reduces payload on large tenants.

    .PARAMETER EnableException
        Throw on failure instead of writing a warning.

    .EXAMPLE
        PS C:\> $delta = @{}
        PS C:\> Get-PSEntraIDContactDelta -DeltaSession $delta

        First call: every contact, and the token is stored in $delta.

    .EXAMPLE
        PS C:\> Get-PSEntraIDContactDelta -DeltaSession $delta | Where-Object Removed

        Subsequent call: only what changed, filtered down to what was removed.

    .EXAMPLE
        PS C:\> $delta = Import-PSEntraIDDeltaSession -Path .\contact.delta.json
        PS C:\> Get-PSEntraIDContactDelta -DeltaSession $delta
        PS C:\> Export-PSEntraIDDeltaSession -Path .\contact.delta.json -DeltaSession $delta

        The scheduled-task shape: load the token, ask for changes, save the new token.
    #>
    [OutputType('PSMicrosoftEntraID.Contacts.ContactDelta')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable] $DeltaSession,

        [Parameter()]
        [switch] $MinimalDelta,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $path = 'contacts/delta'
        # The Get-PSEntraIDContact select list - an unselected delta returns only the
        # default properties and tracks only their changes.
        [hashtable] $query = @{
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Contact).Value -join ',')
        }
    }

    process {
        # Everything this cmdlet does beyond naming its endpoint and its type lives in
        # Invoke-EntraDeltaRequest, shared with the other four delta cmdlets.
        #
        # DeltaSession is splatted rather than passed straight through: "omitted" and
        # "null" mean different things here - omitted reads everything without tracking
        # a token - and only parameter binding can tell the two apart.
        $deltaParameters = @{}
        if ($PSBoundParameters.ContainsKey('DeltaSession')) { $deltaParameters['DeltaSession'] = $DeltaSession }

        Invoke-EntraDeltaRequest -Cmdlet $PSCmdlet -Path $path -TargetType ([PSMicrosoftEntraID.Contacts.ContactDelta]) @deltaParameters -Query $query `
            -MinimalDelta:$MinimalDelta -EnableException:$EnableException
    }

    end {}
}