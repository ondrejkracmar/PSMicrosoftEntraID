using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a license assigned to a group in Microsoft Entra ID.
    /// </summary>
    [DataContract]
    public class AssignedLicense
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AssignedLicense"/> class.
        /// </summary>
        public AssignedLicense()
        {
        }

        /// <summary>
        /// Gets or sets the collection of the unique identifiers (GUIDs) for plans
        /// that have been disabled within this assigned license.
        /// </summary>
        [DataMember(Name = "disabledPlans")]
        public Guid[] DisabledPlans { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier (GUID) for the service SKU.
        /// </summary>
        [DataMember(Name = "skuId")]
        public Guid? SkuId { get; set; }
    }
}