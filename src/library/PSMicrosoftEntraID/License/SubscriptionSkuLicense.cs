using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents a license associated with a subscription SKU in Microsoft Entra ID.
    /// Inherits from the <see cref="SubscriptionSku"/> class and provides additional properties
    /// for account information, capability status, and associated subscription IDs.
    /// </summary>
    public class SubscriptionSkuLicense : SubscriptionSku
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="SubscriptionSkuLicense"/> class.
        /// </summary>
        public SubscriptionSkuLicense()
        {
        }

        /// <summary>
        /// Gets or sets the account name associated with the license.
        /// </summary>
        public string AccountName { get; set; }

        /// <summary>
        /// Gets or sets the account ID associated with the license.
        /// </summary>
        public string AccountId { get; set; }

        /// <summary>
        /// Gets or sets the capability status of the license.
        /// </summary>
        public string CapabilityStatus { get; set; }

        /// <summary>
        /// Gets or sets the list of subscription IDs associated with the license.
        /// </summary>
        public string[] SubscriptionIds { get; set; }
    }
}
