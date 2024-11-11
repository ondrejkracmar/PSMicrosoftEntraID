using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents a specific identifier for a service plan in Microsoft Entra ID.
    /// Inherits from the abstract <see cref="ServicePlan"/> class and provides an additional
    /// property for a friendly name.
    /// </summary>
    [DataContract]
    public class ServicePlanIdentifier : ServicePlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ServicePlanIdentifier"/> class.
        /// </summary>
        public ServicePlanIdentifier()
        {
        }

        /// <summary>
        /// Gets or sets the friendly name of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanFriendlyName")]
        public string ServicePlanFriendlyName { get; set; }
    }
}
