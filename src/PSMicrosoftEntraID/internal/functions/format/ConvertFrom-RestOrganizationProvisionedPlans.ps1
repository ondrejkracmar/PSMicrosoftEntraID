function ConvertFrom-RestOrganizationProvisionedPlans {
    <#
	.SYNOPSIS
		Converts organization provisioned plans to look nice.

	.DESCRIPTION
		Converts organization provisioned plans to look nice.

	.PARAMETER InputObject
		The rest response representing a organization  provisioned plans

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationProvisionedPlans

		Retrieves the organization provisioned plans and converts it into something userfriendly

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
            PSTypeName       = 'PSMicrosoftEntraID.Organization.ProvisionedPlan'
            AssignedDateTime = $InputObject.assignedDateTime
            Service          = $InputObject.service
            AervicePlanId    = $InputObject.servicePlanId
            CapabilityStatus = $InputObject.capabilityStatus
        }
    }
}