using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a resolved overview of a license assigned to a group.
    /// </summary>
    [DataContract]
    public class AssignedLicenseDetail
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AssignedLicenseDetail"/> class.
        /// </summary>
        public AssignedLicenseDetail()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the group.
        /// </summary>
        [DataMember(Name = "groupId")]
        public string GroupId { get; set; }

        /// <summary>
        /// Gets or sets the display name of the group.
        /// </summary>
        [DataMember(Name = "groupDisplayName")]
        public string GroupDisplayName { get; set; }

        /// <summary>
        /// Gets or sets the primary mail address of the group.
        /// </summary>
        [DataMember(Name = "groupMail")]
        public string GroupMail { get; set; }

        /// <summary>
        /// Gets or sets the mail nickname of the group.
        /// </summary>
        [DataMember(Name = "groupMailNickname")]
        public string GroupMailNickname { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier of the assigned SKU.
        /// </summary>
        [DataMember(Name = "skuId")]
        public string SkuId { get; set; }

        /// <summary>
        /// Gets or sets the SKU part number.
        /// </summary>
        [DataMember(Name = "skuPartNumber")]
        public string SkuPartNumber { get; set; }

        /// <summary>
        /// Gets or sets the friendly SKU name.
        /// </summary>
        [DataMember(Name = "skuFriendlyName")]
        public string SkuFriendlyName { get; set; }

        /// <summary>
        /// Gets or sets the identifiers of disabled service plans.
        /// </summary>
        [DataMember(Name = "disabledPlanIds")]
        public string[] DisabledPlanIds { get; set; }

        /// <summary>
        /// Gets or sets the number of disabled service plans.
        /// </summary>
        [DataMember(Name = "disabledPlanCount")]
        public int DisabledPlanCount { get; set; }

        /// <summary>
        /// Gets or sets the number of enabled service plans.
        /// </summary>
        [DataMember(Name = "enabledPlanCount")]
        public int EnabledPlanCount { get; set; }

        /// <summary>
        /// Gets or sets the total number of resolved service plans.
        /// </summary>
        [DataMember(Name = "totalPlanCount")]
        public int TotalPlanCount { get; set; }

        /// <summary>
        /// Gets or sets the resolved service plan details for the assigned SKU.
        /// </summary>
        [DataMember(Name = "servicePlans")]
        public AssignedLicenseServicePlanDetail[] ServicePlans { get; set; }
    }
}