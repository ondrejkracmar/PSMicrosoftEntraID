
function Join-UriPath {
    <#
    .SYNOPSIS
        Join-Path but for URL strings instead

    .DESCRIPTION
        Join-Path but for URL strings instead

    .PARAMETER Uri
        Base path string

    .PARAMETER ChildPath
        Child path or item name

    .EXAMPLE
        PS C:\> Join-Url -Path "https://www.contoso.local" -ChildPath "foo.htm"

        returns "https://www.contoso.local/foo.htm"

    #>
    param (
        [parameter(Mandatory=$True, HelpMessage="Base Path")]
        [ValidateNotNullOrEmpty()]
        [string] $Uri,
        [parameter(Mandatory=$True, HelpMessage="Child Path or Item Name")]
        [ValidateNotNullOrEmpty()]
        [string] $ChildPath
    )
    if ($Uri.EndsWith('/')) {
        return -join ($Uri, $ChildPath)
    }
    else {
        return -join ($Uri,"/",$ChildPath)
    }
}