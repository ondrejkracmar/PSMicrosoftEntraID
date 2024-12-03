using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Runtime.Serialization;
using System.Xml;
using PSMicrosoftEntraID.License;

namespace PSMicrosoftEntraID.Users.LicenseManagement
{
    /// <summary>
    /// Represents an Office 365 subscription SKU (Stock Keeping Unit) for a user.
    /// This class provides properties to hold information about the subscription's unique ID,
    /// SKU details, and assigned service plans.
    /// </summary>
    [DataContract]
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
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Unique identifier (GUID) for the service SKU.
        /// </summary>
        [DataMember(Name = "skuId")]
        public string SkuId { get; set; }

        /// <summary>
        /// Unique SKU display name.
        /// </summary>
        [DataMember(Name = "skuPartNumber")]
        public string SkuPartNumber { get; set; }

        /// <summary>
        /// List of service plans associated with the license.
        /// Contains information about the specific services included in the subscription.
        /// </summary>
        [DataMember(Name = "servicePlans")]
        public ServicePlan[] ServicePlans { get; set; }
    }
}
