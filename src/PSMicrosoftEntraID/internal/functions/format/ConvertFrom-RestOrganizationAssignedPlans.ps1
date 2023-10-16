function ConvertFrom-RestOrganizationAssignedPlans {
    <#
	.SYNOPSIS
		Converts organization assigned plans to look nice.

	.DESCRIPTION
		Converts organization assigned plans to look nice.

	.PARAMETER InputObject
		The rest response representing a organization assigned plans

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganizationAssignedPlans

		Retrieves the organization assigned plans and converts it into something userfriendly

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
            PSTypeName       = 'PSMicrosoftEntraID.Organization.AssignedPlan'
            AssignedDateTime = $InputObject.assignedDateTime
            Service          = $InputObject.service
            AervicePlanId    = $InputObject.servicePlanId
            CapabilityStatus = $InputObject.capabilityStatus
        }
    }
}