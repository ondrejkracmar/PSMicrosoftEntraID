<#
.SYNOPSIS
    Escape a value for safe use inside an OData filter string literal.

.DESCRIPTION
    Escapes single quotes by doubling them, per OData v4 specification.
    Use when interpolating user-supplied values into an OData filter
    expression to avoid injection into the filter clause.

.PARAMETER Value
    The raw value to escape. $null and empty strings are returned unchanged.

.EXAMPLE
    PS C:\> ConvertTo-ODataFilterString -Value "O'Brien"
    O''Brien

.NOTES
    Internal helper.
#>
function ConvertTo-ODataFilterString {
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Value
    )

    process {
        if ([string]::IsNullOrEmpty($Value)) {
            return $Value
        }
        return $Value.Replace("'", "''")
    }
}
