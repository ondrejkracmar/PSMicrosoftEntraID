
function ConvertFrom-RestOrganization {
    <#
	.SYNOPSIS
		Converts tenant organization object to look nice.

	.DESCRIPTION
		Converts tenant organization object to look nice.

	.PARAMETER InputObject
		The rest response representing a subscribed Sku

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path organization -Method Get -ErrorAction Stop | ConvertFrom-RestOrganization

		Retrieves the specified tenant organization information and converts it into something userfriendly

	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    process {
        if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.id)) ) { return }
        [PSCustomObject]@{
            PSTypeName                                = 'PSMicrosoftEntraID.Organization'
            TenantId                                  = $InputObject.id
            DisplayName                               = $InputObject.displayName
            TenantType                                = $InputObject.tenantType
            IsMultipleDataLocationsForServicesEnabled = $InputObject.isMultipleDataLocationsForServicesEnabled
            OnPremisesLastSyncDateTime                = $InputObject.OnPremisesLastSyncDateTime
            OnPremisesNextSyncDateTime                = (Get-Date $InputObject.OnPremisesLastSyncDateTime).AddSeconds((Get-PSFConfigValue -FullName ('{0}.Settings.Organization.OnPremisesSyncPeriod' -f $script:ModuleName)))
            OnPremisesSyncEnabled                     = $InputObject.OnPremisesSyncEnabled
            OnPremisesSyncStatus                      = $InputObject.OnPremisesSyncStatus | ConvertFrom-RestOrganizationOnPremisesSyncStatus
            PartnerTenantType                         = $InputObject.partnerTenantType
            CreatedDateTime                           = $InputObject.createdDateTime
            DeletedDateTime                           = $InputObject.deletedDateTime
            DirectorySizeQuota                        = $InputObject.directorySizeQuota | ConvertFrom-RestOrganizationDirectorySizeQuota
            CountryLetterCode                         = $InputObject.countryLetterCode
            DefaultUsageLocation                      = $InputObject.defaultUsageLocation
            PreferredLanguage                         = $InputObject.preferredLanguage
            Street                                    = $InputObject.street
            City                                      = $InputObject.city
            PostalCode                                = $InputObject.postalCode
            State                                     = $InputObject.state
            Country                                   = $InputObject.countryLetterCode
            BusinessPhones                            = $InputObject.businessPhones
            TechnicalNotificationMails                = $InputObject.technicalNotificationMails
            SecurityComplianceNotificationMails       = $InputObject.securityComplianceNotificationMails
            SecurityComplianceNotificationPhones      = $InputObject.securityComplianceNotificationPhones
            PrivacyProfile                            = $InputObject.privacyProfile
            AssignedPlans                             = $InputObject.assignedPlans | ConvertFrom-RestOrganizationAssignedPlans
            ProvisionedPlans                          = $InputObject.provisionedPlans | ConvertFrom-RestOrganizationProvisionedPlans
            VerifiedDomains                           = $InputObject.verifiedDomains | ConvertFrom-RestOrganizationVerifiedDomains
        }
    }
}