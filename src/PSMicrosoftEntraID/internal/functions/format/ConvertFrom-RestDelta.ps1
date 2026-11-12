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

        The typed delta models map all of it themselves (GraphJson, [JsonPropertyName]):
        "@removed" sets ChangeType, "members@delta" fills MembersDelta, a member's
        "@odata.type" fills ObjectType and its own "@removed" sets Removed. This function
        only unwraps the page and hands the whole set to ConvertFrom-GraphResponse - one
        serialization and one deserialization per page, whatever its size.

        A removed object arrives with little more than its id - Graph does not resend the
        rest of something that is gone. Expected, not a conversion failure.

    .PARAMETER InputObject
        The delta response: its JSON text, the parsed page, or the individual value entries from one.

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

    $entries = if ($InputObject -isnot [string] -and $InputObject.PSObject.Properties['value']) { $InputObject.value } else { $InputObject }
    ConvertFrom-GraphResponse -InputObject $entries -Type $TargetType
}
