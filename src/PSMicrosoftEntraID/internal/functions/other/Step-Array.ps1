function Step-Array {
    <#
    .SYNOPSIS
        Slice a PowerShell array into groups of smaller arrays.

    .DESCRIPTION
        Slice a PowerShell array into groups of smaller arrays.

    .PARAMETER Item
        Array of strings.

    .PARAMETER Size
        Size of smaller array

    .EXAMPLE
        PS C:\> Step-Array -Item $stringarray -Size 20

		Slice array

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
        [String[]]$Item,
        [int]$Size = 10
    )
    begin {
        $Items = @()
    }
    process {
        foreach ($i in $Item ) { $Items += $i }
    }
    end {
        0..[math]::Floor($Items.count / $Size) | ForEach-Object {
            $x, $Items = $Items[0..($Size - 1)], $Items[$Size..$Items.Length]; , $x
        }
    }
}