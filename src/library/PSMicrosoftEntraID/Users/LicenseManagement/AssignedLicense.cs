using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Users.LicenseManagement
{
    /// <summary>
    /// Represents an assigned license in Microsoft Entra ID.
    /// This class contains properties for identifying the service SKU and
    /// the plans that are disabled under this license.
    /// </summary>
    [DataContract]
    public class AssignedLicense
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AssignedLicense"/> class.
        /// Creates an empty assigned license.
        /// </summary>
        public AssignedLicense()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier (GUID) for the service SKU.
        /// </summary>
        [DataMember(Name = "skuId")]
        public string SkuId { get; set; }

        /// <summary>
        /// Gets or sets the list of disabled plans under this license.
        /// </summary>
        [DataMember(Name = "disabledPlans")]
        public string[] DisabledPlans { get; set; }
    }
}
