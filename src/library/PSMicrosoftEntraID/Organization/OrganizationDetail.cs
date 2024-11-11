using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents the details of an organization (tenant) in Microsoft Entra ID.
    /// This class provides properties for tenant identification, display settings,
    /// synchronization details, contact information, and various settings.
    /// </summary>
    [DataContract]
    public class OrganizationDetail
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="OrganizationDetail"/> class.
        /// </summary>
        public OrganizationDetail()
        {
        }

        /// <summary>
        /// Gets or sets the tenant ID, a unique identifier representing the organization (or tenant).
        /// </summary>
        [DataMember(Name = "id")]
        public string TenantId { get; set; }

        /// <summary>
        /// Gets or sets the display name for the tenant.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the type of tenant.
        /// </summary>
        [DataMember(Name = "tenantType")]
        public string TenantType { get; set; }

        /// <summary>
        /// Indicates if multiple data locations for services are enabled.
        /// </summary>
        [DataMember(Name = "isMultipleDataLocationsForServicesEnabled")]
        public string IsMultipleDataLocationsForServicesEnabled { get; set; }

        /// <summary>
        /// Gets or sets the last synchronization date and time for on-premises.
        /// </summary>
        [DataMember(Name = "onPremisesLastSyncDateTime")]
        public string OnPremisesLastSyncDateTime { get; set; }

        /// <summary>
        /// Gets or sets the next synchronization date and time for on-premises.
        /// </summary>
        [DataMember(Name = "onPremisesNextSyncDateTime")]
        public string OnPremisesNextSyncDateTime { get; set; }

        /// <summary>
        /// Indicates if on-premises synchronization is enabled.
        /// </summary>
        [DataMember(Name = "onPremisesSyncEnabled")]
        public bool OnPremisesSyncEnabled { get; set; }

        /// <summary>
        /// Gets or sets the status of on-premises synchronization.
        /// </summary>
        [DataMember(Name = "onPremisesSyncStatus")]
        public OnPremisesSyncStatus OnPremisesSyncStatus { get; set; }

        /// <summary>
        /// Gets or sets the partner tenant type.
        /// </summary>
        [DataMember(Name = "partnerTenantType")]
        public string PartnerTenantType { get; set; }

        /// <summary>
        /// Gets or sets the creation date and time of the tenant.
        /// </summary>
        [DataMember(Name = "createdDateTime")]
        public string CreatedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the deletion date and time of the tenant.
        /// </summary>
        [DataMember(Name = "deletedDateTime")]
        public string DeletedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the directory size quota information.
        /// </summary>
        [DataMember(Name = "directorySizeQuota")]
        public DirectorySizeQuota DirectorySizeQuota { get; set; }

        /// <summary>
        /// Gets or sets the country letter code for the tenant.
        /// </summary>
        [DataMember(Name = "countryLetterCode")]
        public string CountryLetterCode { get; set; }

        /// <summary>
        /// Gets or sets the default usage location for the tenant.
        /// </summary>
        [DataMember(Name = "defaultUsageLocation")]
        public string DefaultUsageLocation { get; set; }

        /// <summary>
        /// Gets or sets the preferred language for the tenant.
        /// </summary>
        [DataMember(Name = "preferredLanguage")]
        public string PreferredLanguage { get; set; }

        /// <summary>
        /// Gets or sets the street address of the organization.
        /// </summary>
        [DataMember(Name = "street")]
        public string Street { get; set; }

        /// <summary>
        /// Gets or sets the city where the organization is located.
        /// </summary>
        [DataMember(Name = "city")]
        public string City { get; set; }

        /// <summary>
        /// Gets or sets the postal code of the organization's location.
        /// </summary>
        [DataMember(Name = "postalCode")]
        public string PostalCode { get; set; }

        /// <summary>
        /// Gets or sets the state where the organization is located.
        /// </summary>
        [DataMember(Name = "state")]
        public string State { get; set; }

        /// <summary>
        /// Gets or sets the country where the organization is located.
        /// </summary>
        [DataMember(Name = "country")]
        public string Country { get; set; }

        /// <summary>
        /// Gets or sets a collection of business phone numbers for the organization.
        /// </summary>
        [DataMember(Name = "businessPhones")]
        public string[] BusinessPhones { get; set; }

        /// <summary>
        /// Gets or sets a collection of technical notification email addresses.
        /// </summary>
        [DataMember(Name = "technicalNotificationMails")]
        public string[] TechnicalNotificationMails { get; set; }

        /// <summary>
        /// Gets or sets a collection of security compliance notification email addresses.
        /// </summary>
        [DataMember(Name = "securityComplianceNotificationMails")]
        public string[] SecurityComplianceNotificationMails { get; set; }

        /// <summary>
        /// Gets or sets a collection of security compliance notification phone numbers.
        /// </summary>
        [DataMember(Name = "securityComplianceNotificationPhones")]
        public string[] SecurityComplianceNotificationPhones { get; set; }

        /// <summary>
        /// Gets or sets the privacy profile for the organization.
        /// </summary>
        [DataMember(Name = "privacyProfile")]
        public string PrivacyProfile { get; set; }

        /// <summary>
        /// Gets or sets the assigned plans for the organization.
        /// </summary>
        [DataMember(Name = "assignedPlans")]
        public AssignedPlan[] AssignedPlans { get; set; }

        /// <summary>
        /// Gets or sets the provisioned plans for the organization.
        /// </summary>
        [DataMember(Name = "provisionedPlans")]
        public ProvisionedPlan[] ProvisionedPlans { get; set; }

        /// <summary>
        /// Gets or sets the verified domains for the organization.
        /// </summary>
        [DataMember(Name = "verifiedDomains")]
        public VerifiedDomain[] VerifiedDomains { get; set; }
    }
}
