function Get-PSEntraIDUsageLocation {
    <#
	.SYNOPSIS
		Get User Usage Location hashtable.

	.DESCRIPTION
		Get User Ysage Location hashtable.

	.EXAMPLE
		PS C:\> Get-UserUsageLocation

        Get list of usage locations
	#>
    [OutputType('System.Collections.Hashtable')]
    [CmdletBinding()]
    param (

    )
    begin {
        $usageLocationTemplate = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'aadtemplate' -ChildPath 'UsageLocation.json' )
        $usageLocationHash = Get-Content -Path $usageLocationTemplate | ConvertFrom-Json | ConvertTo-PSFHashtable
    }
    process {
        return $usageLocationHash
    }
}