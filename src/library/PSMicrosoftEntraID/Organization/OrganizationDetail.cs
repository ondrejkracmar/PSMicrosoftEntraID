using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.Json.Serialization;
using PSMicrosoftEntraID.Serialization;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents the details of an organization (tenant) in Microsoft Entra ID.
    /// This class provides properties for tenant identification, display settings,
    /// synchronization details, contact information, and various settings.
    /// </summary>
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
        [JsonPropertyName("id")]
        public string TenantId { get; set; }

        /// <summary>
        /// Gets or sets the display name for the tenant.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the type of tenant.
        /// </summary>
        public string TenantType { get; set; }

        /// <summary>
        /// Indicates if multiple data locations for services are enabled.
        /// </summary>
        public bool? IsMultipleDataLocationsForServicesEnabled { get; set; }

        /// <summary>
        /// Gets or sets the last synchronization date and time for on-premises.
        /// </summary>
        public DateTime? OnPremisesLastSyncDateTime { get; set; }

        /// <summary>
        /// Gets or sets the next synchronization date and time for on-premises.
        /// </summary>
        public DateTime? OnPremisesNextSyncDateTime { get; set; }

        /// <summary>
        /// Indicates if on-premises synchronization is enabled.
        /// </summary>
        public bool? OnPremisesSyncEnabled { get; set; }

        /// <summary>
        /// Gets or sets the status of on-premises synchronization.
        /// </summary>
        [JsonConverter(typeof(SingleOrFirstConverter<OnPremisesSyncStatus>))]
        public OnPremisesSyncStatus OnPremisesSyncStatus { get; set; }

        /// <summary>
        /// Gets or sets the partner tenant type.
        /// </summary>
        public string PartnerTenantType { get; set; }

        /// <summary>
        /// Gets or sets the creation date and time of the tenant.
        /// </summary>
        public DateTime? CreatedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the deletion date and time of the tenant.
        /// </summary>
        public DateTime? DeletedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the directory size quota information.
        /// </summary>
        public DirectorySizeQuota DirectorySizeQuota { get; set; }

        /// <summary>
        /// Gets or sets the country letter code for the tenant.
        /// </summary>
        public string CountryLetterCode { get; set; }

        /// <summary>
        /// Gets or sets the default usage location for the tenant.
        /// </summary>
        public string DefaultUsageLocation { get; set; }

        /// <summary>
        /// Gets or sets the preferred language for the tenant.
        /// </summary>
        public string PreferredLanguage { get; set; }

        /// <summary>
        /// Gets or sets the street address of the organization.
        /// </summary>
        public string Street { get; set; }

        /// <summary>
        /// Gets or sets the city where the organization is located.
        /// </summary>
        public string City { get; set; }

        /// <summary>
        /// Gets or sets the postal code of the organization's location.
        /// </summary>
        public string PostalCode { get; set; }

        /// <summary>
        /// Gets or sets the state where the organization is located.
        /// </summary>
        public string State { get; set; }

        /// <summary>
        /// Gets or sets the country where the organization is located.
        /// </summary>
        public string Country { get; set; }

        /// <summary>
        /// Gets or sets a collection of business phone numbers for the organization.
        /// </summary>
        public string[] BusinessPhones { get; set; }

        /// <summary>
        /// Gets or sets a collection of technical notification email addresses.
        /// </summary>
        public string[] TechnicalNotificationMails { get; set; }

        /// <summary>
        /// Gets or sets a collection of security compliance notification email addresses.
        /// </summary>
        public string[] SecurityComplianceNotificationMails { get; set; }

        /// <summary>
        /// Gets or sets a collection of security compliance notification phone numbers.
        /// </summary>
        public string[] SecurityComplianceNotificationPhones { get; set; }

        /// <summary>
        /// Gets or sets the privacy profile for the organization.
        /// </summary>
        public PrivacyProfile PrivacyProfile { get; set; }

        /// <summary>
        /// Gets or sets the assigned plans for the organization.
        /// </summary>
        public AssignedPlan[] AssignedPlans { get; set; }

        /// <summary>
        /// Gets or sets the provisioned plans for the organization.
        /// </summary>
        public ProvisionedPlan[] ProvisionedPlans { get; set; }

        /// <summary>
        /// Gets or sets the verified domains for the organization.
        /// </summary>
        public VerifiedDomain[] VerifiedDomains { get; set; }
    }
}
