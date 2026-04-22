using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a resolved service plan state within a group assigned license.
    /// </summary>
    [DataContract]
    public class AssignedLicenseServicePlanDetail
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AssignedLicenseServicePlanDetail"/> class.
        /// </summary>
        public AssignedLicenseServicePlanDetail()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanId")]
        public string ServicePlanId { get; set; }

        /// <summary>
        /// Gets or sets the technical name of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanName")]
        public string ServicePlanName { get; set; }

        /// <summary>
        /// Gets or sets the friendly name of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanFriendlyName")]
        public string ServicePlanFriendlyName { get; set; }

        /// <summary>
        /// Gets or sets the AppliesTo value from the subscribed SKU metadata.
        /// </summary>
        [DataMember(Name = "appliesTo")]
        public string AppliesTo { get; set; }

        /// <summary>
        /// Gets or sets the provisioning status of the service plan.
        /// </summary>
        [DataMember(Name = "provisioningStatus")]
        public string ProvisioningStatus { get; set; }

        /// <summary>
        /// Gets or sets the readable state of the service plan.
        /// </summary>
        [DataMember(Name = "status")]
        public string Status { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the service plan is disabled.
        /// </summary>
        [DataMember(Name = "isDisabled")]
        public bool IsDisabled { get; set; }
    }
}