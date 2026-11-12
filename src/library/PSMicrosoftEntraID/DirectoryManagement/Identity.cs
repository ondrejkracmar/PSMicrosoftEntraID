namespace PSMicrosoftEntraID.DirectoryManagement
{
    /// <summary>
    /// Represents identity information for a role member in a scoped role membership, as per Microsoft Graph API.
    /// </summary>
    public class Identity
    {
        /// <summary>
        /// Gets or sets the unique identifier for the identity or actor.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the display name of the identity.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the unique identity of the tenant. Optional.
        /// </summary>
        public string TenantId { get; set; }
    }
}