using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents a provisioned plan in Microsoft Entra ID.
    /// This class provides properties for the capability status, provisioning status, and service.
    /// </summary>
    [DataContract]
    public class ProvisionedPlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ProvisionedPlan"/> class.
        /// </summary>
        public ProvisionedPlan()
        {
        }

        /// <summary>
        /// Gets or sets the capability status of the provisioned plan.
        /// </summary>
        [DataMember(Name = "capabilityStatus")]
        public string CapabilityStatus { get; set; }

        /// <summary>
        /// Gets or sets the provisioning status of the plan.
        /// </summary>
        [DataMember(Name = "provisioningStatus")]
        public string ProvisioningStatus { get; set; }

        /// <summary>
        /// Gets or sets the name of the service associated with the provisioned plan.
        /// </summary>
        [DataMember(Name = "service")]
        public string Service { get; set; }
    }
}
