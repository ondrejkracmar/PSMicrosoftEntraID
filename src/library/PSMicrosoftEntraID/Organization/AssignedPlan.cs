using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents an assigned plan for an organization in Microsoft Entra ID.
    /// This class contains properties for the assignment date, service, service plan ID, and capability status.
    /// </summary>
    [DataContract]
    public class AssignedPlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="AssignedPlan"/> class.
        /// </summary>
        public AssignedPlan()
        {
        }

        /// <summary>
        /// Gets or sets the date and time when the plan was assigned.
        /// </summary>
        [DataMember(Name = "assignedDateTime")]
        public string AssignedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the name of the service associated with the plan.
        /// </summary>
        [DataMember(Name = "service")]
        public string Service { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier of the service plan.
        /// </summary>
        [DataMember(Name = "servicePlanId")]
        public string ServicePlanId { get; set; }

        /// <summary>
        /// Gets or sets the capability status of the assigned plan.
        /// </summary>
        [DataMember(Name = "capabilityStatus")]
        public string CapabilityStatus { get; set; }
    }
}
