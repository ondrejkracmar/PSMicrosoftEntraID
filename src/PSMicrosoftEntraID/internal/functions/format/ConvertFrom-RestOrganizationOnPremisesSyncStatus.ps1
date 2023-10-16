function ConvertFrom-RestOrganizationOnPremisesSyncStatus {
    <#
	.SYNOPSIS
		Converts OnPremises sync status to look nice.

	.DESCRIPTION
		Converts OnPremises sync status to look nice.

	.PARAMETER InputObject
		The rest response representing a OnPremises sync status

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationOnPremisesSyncStatus

		Retrieves the OnPremises sync status and converts it into something userfriendly

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
            PSTypeName       = 'PSMicrosoftEntraID.Organization.OnPremisesSyncStatus'
            AttributeSetName = $InputObject.attributeSetName
            State            = $InputObject.state
            Version          = $InputObject.version
        }
    }
}