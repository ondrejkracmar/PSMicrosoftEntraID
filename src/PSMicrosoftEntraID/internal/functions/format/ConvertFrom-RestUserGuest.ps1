function ConvertFrom-RestUserGuest {
    <#
    .SYNOPSIS
        Converts user objects from REST response to UserGuest objects.

    .DESCRIPTION
        Converts user objects from REST response to a structured format
        using the PSMicrosoftEntraID.Users.UserGuest type.

    .PARAMETER InputObject
        The REST response representing a user or an array of users.

    .EXAMPLE
        PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestUserGuest

        Retrieves Guest users and converts them into a user-friendly format.

    .NOTES
        Author: Your Name
        Last Updated: 2025-03-06
    #>

    [CmdletBinding()]
    param (
        $InputObject
    )

    if (-not $InputObject) { return }

    ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Users.UserGuest])
}
