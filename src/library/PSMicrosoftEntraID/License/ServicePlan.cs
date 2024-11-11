using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents an abstract service plan for an Office 365 subscription.
    /// This class provides properties for the service plan's unique identifier and name.
    /// </summary>
    [DataContract]
    public abstract class ServicePlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ServicePlan"/> class.
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
    }
}
