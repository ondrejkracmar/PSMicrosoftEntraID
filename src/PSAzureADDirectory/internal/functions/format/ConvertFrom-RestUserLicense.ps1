function ConvertFrom-RestUserLicense {
	<#
	.SYNOPSIS
		Converts license objects to look nice.

	.DESCRIPTION
		Converts license objects to look nice.

	.PARAMETER InputObject
		The rest response representing a license

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestLicense
		Retrieves the specified license and converts it into something userfriendly
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		[switch]$ServicePlan
	)
	begin {

	}
	process {
		if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.id)) ) { return }

		if ($ServicePlan.IsPresent) {
			
			[PSCustomObject]@{
				PSTypeName        = 'PSAzureADDirectory.User.License'
				Id                = $InputObject.id
				UserPrincipalName = $InputObject.userPrincipalName
				UserType          = $InputObject.userType
				AccountEnabled    = $InputObject.accountEnabled
				DisplayName       = $InputObject.displayName
				Mail              = $InputObject.mail
				UsageLocation     = $InputObject.usageLocation
				CompanyName       = $InputObject.companyName
				AssignedLicenses  = ($InputObject.assignedLicenses | ConvertFrom-RestUserLicenseServicePlan -ServicePlan)
			}
		}
		else {
			
			[PSCustomObject]@{
				PSTypeName        = 'PSAzureADDirectory.User.License'
				Id                = $InputObject.id
				UserPrincipalName = $InputObject.userPrincipalName
				UserType          = $InputObject.userType
				AccountEnabled    = $InputObject.accountEnabled
				DisplayName       = $InputObject.displayName
				Mail              = $InputObject.mail
				UsageLocation     = $InputObject.usageLocation
				CompanyName       = $InputObject.companyName
				AssignedLicenses  = ($InputObject.assignedLicenses | ConvertFrom-RestUserLicenseServicePlan)
			}		
		}
	}
}