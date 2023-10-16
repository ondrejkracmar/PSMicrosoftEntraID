function ConvertFrom-RestOrganizationVerifiedDomains {
    <#
	.SYNOPSIS
		Converts organization verified domains to look nice.

	.DESCRIPTION
		Converts organization verified domains to look nice.

	.PARAMETER InputObject
		The rest response representing a organization verified domains

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationVerifiedDomains

		Retrieves the organization verified domains and converts it into something userfriendly

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
            PSTypeName   = 'PSMicrosoftEntraID.Organization.VerifiedDomain'
            Capabilities = $InputObject.capabilities
            IsDefault    = $InputObject.isDefault
            IsInitial    = $InputObject.IsInitial
            Name         = $InputObject.name
            Type         = $InputObject.type
        }
    }
}