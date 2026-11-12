using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Xml;
using PSMicrosoftEntraID.License;

namespace PSMicrosoftEntraID.Users.LicenseManagement
{
    /// <summary>
    /// Represents an Office 365 subscription SKU (Stock Keeping Unit) for a user.
    /// This class provides properties to hold information about the subscription's unique ID,
    /// SKU details, and assigned service plans.
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
        /// Unique identifier for the license detail object.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Unique identifier (GUID) for the service SKU.
        /// </summary>
        public string SkuId { get; set; }

        /// <summary>
        /// Unique SKU display name.
        /// </summary>
        public string SkuPartNumber { get; set; }

        /// <summary>
        /// Friendly name of the SKU.
        /// </summary>
        public string SkuFriendlyName { get; set; }

        /// <summary>
        /// List of service plans associated with the license.
        /// Contains information about the specific services included in the subscription.
        /// </summary>
        public ServicePlan[] ServicePlans { get; set; }
    }
}
