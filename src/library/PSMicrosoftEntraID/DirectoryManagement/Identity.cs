using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.DirectoryManagement
{
    /// <summary>
    /// Represents identity information for a role member in a scoped role membership, as per Microsoft Graph API.
    /// </summary>
    [DataContract]
    public class Identity
    {
        /// <summary>
        /// Gets or sets the unique identifier for the identity or actor.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the display name of the identity.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the unique identity of the tenant. Optional.
        /// </summary>
        [DataMember(Name = "tenantId")]
        public string TenantId { get; set; }
    }
}