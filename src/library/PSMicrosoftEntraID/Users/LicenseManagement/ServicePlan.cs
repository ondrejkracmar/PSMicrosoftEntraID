using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Users.LicenseManagement
{
    /// <summary>
    /// Represents a service plan in an Office 365 subscription.
    /// This class provides properties to hold the service plan's unique ID, name, 
    /// applicable assignments, and provisioning status.
    /// </summary>
    [DataContract]
    public class ServicePlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ServicePlan"/> class.
        /// Creates an empty service plan.
        /// </summary>
        public ServicePlan()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanId")]
        public string ServicePlanId { get; set; }

        /// <summary>
        /// Gets or sets the name of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanName")]
        public string ServicePlanName { get; set; }

        /// <summary>
        /// Gets or sets the target object to which the service plan can be assigned.
        /// </summary>
        [DataMember(Name = "appliesTo")]
        public string AppliesTo { get; set; }

        /// <summary>
        /// Gets or sets the provisioning status of the service plan.
        /// </summary>
        [DataMember(Name = "provisioningStatus")]
        public string ProvisioningStatus { get; set; }
    }
}
