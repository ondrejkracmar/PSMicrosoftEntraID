using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents a license identifier in Microsoft Entra ID.
    /// This class provides properties for SKU identification, part number, friendly name, and associated service plans.
    /// </summary>
    [DataContract]
    public class LicenseIdentifier
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="LicenseIdentifier"/> class.
        /// </summary>
        public LicenseIdentifier()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier (GUID) for the SKU.
        /// </summary>
        [DataMember(Name = "skuId")]
        public string SkuId { get; set; }

        /// <summary>
        /// Gets or sets the SKU part number.
        /// </summary>
        [DataMember(Name = "skuPartNumber")]
        public string SkuPartNumber { get; set; }

        /// <summary>
        /// Gets or sets the friendly name for the SKU.
        /// </summary>
        [DataMember(Name = "skuFriendlyName")]
        public string SkuFriendlyName { get; set; }

        /// <summary>
        /// Gets or sets the collection of service plans associated with the SKU.
        /// </summary>
        [DataMember(Name = "servicePlans")]
        public ServicePlanIdentifier[] ServicePlans { get; set; }
    }
}
