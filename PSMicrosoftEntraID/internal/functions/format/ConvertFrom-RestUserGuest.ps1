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

    $jsonString = $InputObject | ConvertTo-Json -Depth 4

    $type = if ($InputObject -is [array]) {
        [PSMicrosoftEntraID.Users.UserGuest[]]
    }
    else {
        [PSMicrosoftEntraID.Users.UserGuest]
    }

    [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)

    $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    $stream = [System.IO.MemoryStream]::new($byteArray)
    $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new($type)
    return $serializer.ReadObject($stream)
}
