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

    param (
        $InputObject
    )

    if (-not $InputObject) { return }

    $jsonString = $InputObject | ConvertTo-Json -Depth 4
    [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
    [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)

    if ($InputObject -is [array]) {
        [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Users.UserGuest[]])
    }
    else {
        [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Users.UserGuest])
    }

    return $serializer.ReadObject($stream)
}
