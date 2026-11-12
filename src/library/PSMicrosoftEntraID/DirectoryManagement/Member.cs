using System;

namespace PSMicrosoftEntraID.DirectoryManagement
{
    /// <summary>
    /// Represents a member (user, group, or device) in an administrative unit, as per Microsoft Graph API.
    /// </summary>
    public class Member
    {
        /// <summary>
        /// Gets or sets the unique identifier for the member object.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the date and time when this object was deleted. Always null when the object hasn't been deleted.
        /// </summary>
        public DateTime? DeletedDateTime { get; set; }

        // Add additional properties as needed based on your use case or Graph API schema
    }
}