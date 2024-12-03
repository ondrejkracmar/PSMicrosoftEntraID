using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents a service plan associated with a subscription SKU in Microsoft Entra ID.
    /// Inherits from the abstract <see cref="ServicePlan"/> class and provides additional properties
    /// for provisioning status and applicable scope.
    /// </summary>
    [DataContract]
    public class ServicePlanSubscriptionSku : ServicePlan
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="ServicePlanSubscriptionSku"/> class.
        /// </summary>
        public ServicePlanSubscriptionSku()
        {
        }

        /// <summary>
        /// Gets or sets the provisioning status of the service plan.
        /// </summary>
        [DataMember(Name = "provisioningStatus")]
        public string ProvisioningStatus { get; set; }

        /// <summary>
        /// Gets or sets the applicable scope of the service plan (e.g., User or Organization).
        /// </summary>
        [DataMember(Name = "appliesTo")]
        public string AppliesTo { get; set; }
    }
}
