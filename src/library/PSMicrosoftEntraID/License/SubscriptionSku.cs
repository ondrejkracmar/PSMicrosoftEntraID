using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Xml;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents a subscription SKU (Stock Keeping Unit) for an Office 365 license in Microsoft Entra ID.
    /// This class provides properties for SKU identification, display name, applicable scope, units consumed,
    /// prepaid units, and associated service plans.
    /// </summary>
    public class SubscriptionSku
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="SubscriptionSku"/> class.
        /// Creates an empty subscription.
        /// </summary>
        public SubscriptionSku()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier for the license detail object.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier (GUID) for the service SKU.
        /// </summary>
        public string SkuId { get; set; }

        /// <summary>
        /// Gets or sets the SKU display name.
        /// </summary>
        public string SkuPartNumber { get; set; }

        /// <summary>
        /// Gets or sets the friendly name for the SKU.
        /// </summary>
        public string SkuFriendlyName { get; set; }

        /// <summary>
        /// Gets or sets the applicable scope of the SKU (e.g., User or Organization).
        /// </summary>
        public string AppliesTo { get; set; }

        /// <summary>
        /// Gets or sets the number of units consumed under this SKU.
        /// </summary>
        public int? ConsumedUnits { get; set; }

        /// <summary>
        /// Gets or sets the prepaid units available under this SKU.
        /// </summary>
        public PrepaidUnit PrepaidUnits { get; set; }

        /// <summary>
        /// Gets or sets the collection of service plans associated with this SKU.
        /// </summary>
        public ServicePlanSubscriptionSku[] ServicePlans { get; set; }
    }
}
