namespace PSMicrosoftEntraID.DirectoryManagement
{
    /// <summary>
    /// Represents a scoped role member in an administrative unit, as per Microsoft Graph API.
    /// </summary>
    public class ScopedRoleMember
    {
        /// <summary>
        /// Gets or sets the unique identifier for the scoped-role membership.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier for the directory role that the member is in.
        /// </summary>
        public string RoleId { get; set; }

        /// <summary>
        /// Gets or sets the unique identifier for the administrative unit that the directory role is scoped to.
        /// </summary>
        public string AdministrativeUnitId { get; set; }

        /// <summary>
        /// Gets or sets the role member identity information. Represents the user that is a member of this scoped-role.
        /// </summary>
        public Identity RoleMemberInfo { get; set; }
    }
}