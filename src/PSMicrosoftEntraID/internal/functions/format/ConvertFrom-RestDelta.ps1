function ConvertFrom-RestDelta {
    <#
    .SYNOPSIS
        Converts a delta response into the strongly typed delta object for that resource.

    .DESCRIPTION
        One converter for every delta endpoint, because the shape they add is identical:
        an optional "@removed" annotation, and for groups a "members@delta" list.

        Graph says what happened in an awkward way. A changed object carries no
        annotation at all, so "changed" is the absence of information; a vanished one
        carries "@removed" whose reason is confusingly named:

            (no annotation)           -> Changed
            @removed.reason = changed -> Deleted   (soft-deleted, still restorable)
            @removed.reason = deleted -> Purged    (gone for good)

        That becomes the DeltaChangeType enum so callers switch on a name instead of
        probing for an annotation.

        PERFORMANCE. A delta page can hold thousands of objects, so this serializes the
        whole page ONCE and deserializes it ONCE, then walks the raw entries alongside
        the typed results to stamp the change type. The obvious per-object implementation
        costs three JSON round-trips each, which is minutes rather than seconds on a
        large tenant.

        The annotations are left in the JSON rather than stripped: DataContract ignores
        members it does not know, so removing them would only cost another copy of every
        object.

        A removed object arrives with little more than its id - Graph does not resend the
        rest of something that is gone. Expected, not a conversion failure.

    .PARAMETER InputObject
        The parsed delta response, or the individual value entries from one.

    .PARAMETER TargetType
        The delta type to produce, e.g. [PSMicrosoftEntraID.Users.UserDelta].

    .EXAMPLE
        PS C:\> ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta])

        Turns one raw delta page into typed objects, each stamped with its ChangeType.
    #>
    [CmdletBinding()]
    param (
        $InputObject,

        [Parameter(Mandatory = $true)]
        [type] $TargetType
    )

    if (-not $InputObject) { return }

    $entries = if ($InputObject.PSObject.Properties['value']) { @($InputObject.value) } else { @($InputObject) }
    $entries = @($entries | Where-Object { $_ })
    if ($entries.Count -eq 0) { return }

    # One serialize, one deserialize, for the whole page.
    # The unary comma keeps a single-entry page an array so the [] type still binds.
    $jsonString = , $entries | ConvertTo-Json -Depth 6
    $arrayType = ($TargetType.MakeArrayType())
    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    $stream = [System.IO.MemoryStream]::new($byteArray)
    $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($arrayType)
    $converted = @($serializer.ReadObject($stream))

    $hasMembers = $TargetType.GetProperty('MembersDelta')

    for ($i = 0; $i -lt $converted.Count; $i++) {
        $typed = $converted[$i]
        $raw = $entries[$i]

        if ($raw.PSObject.Properties['@removed']) {
            # See the reason mapping above - Graph's naming is inverted from intuition.
            $typed.ChangeType = if ([string]$raw.'@removed'.reason -eq 'deleted') { 'Purged' } else { 'Deleted' }
        }

        # members@delta cannot round-trip through DataContract: '@odata.type' does not
        # survive its naming rules. Built directly instead, and only for the one type
        # that has the property.
        if ($hasMembers -and $raw.PSObject.Properties['members@delta']) {
            $typed.MembersDelta = [PSMicrosoftEntraID.Groups.GroupMemberDelta[]] @(
                foreach ($member in @($raw.'members@delta')) {
                    if (-not $member) { continue }
                    [PSMicrosoftEntraID.Groups.GroupMemberDelta]@{
                        Id         = [string]$member.id
                        ObjectType = [string]$member.'@odata.type'
                        Removed    = [bool]$member.PSObject.Properties['@removed']
                    }
                })
        }

        $typed
    }
}
