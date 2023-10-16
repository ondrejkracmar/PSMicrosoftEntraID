function ConvertFrom-RestOrganizationDirectorySizeQuota {
    <#
	.SYNOPSIS
		Converts directory size quota to look nice.

	.DESCRIPTION
		Converts directory size quota to look nice.

	.PARAMETER InputObject
		The rest response representing a directory size quota

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationDirectorySizeQuota

		Retrieves the directory size quota and converts it into something userfriendly

	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )
    begin {

    }
    process {
        [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Organization.DirectorySizeQuota'
            Used       = $InputObject.used
            Total      = $InputObject.total
        }
    }
}