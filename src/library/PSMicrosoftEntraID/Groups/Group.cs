using System;
using PSMicrosoftEntraID.Groups.LicenseManagement;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a group in Microsoft Entra ID.
    /// This class provides properties for group identification, contact information, settings, and membership rules.
    /// </summary>
    public class Group
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="Group"/> class.
        /// </summary>
        public Group()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the group.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was created.
        /// </summary>
        public DateTime? CreatedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the email address of the group.
        /// </summary>
        public string Mail { get; set; }

        /// <summary>
        /// Gets or sets the nickname or alias of the group's email.
        /// </summary>
        public string MailNickname { get; set; }

        /// <summary>
        /// Gets or sets the collection of proxy addresses for the group.
        /// </summary>
        public string[] ProxyAddresses { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group is mail-enabled.
        /// </summary>
        public bool? MailEnabled { get; set; }

        /// <summary>
        /// Gets or sets the visibility of the group.
        /// </summary>
        public string Visibility { get; set; }

        /// <summary>
        /// Gets or sets the display name of the group.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the description of the group.
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the types of the group.
        /// </summary>
        public string[] GroupTypes { get; set; }

        /// <summary>
        /// Gets or sets the creation options for the group.
        /// </summary>
        public string[] CreationOptions { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was deleted.
        /// </summary>
        public DateTime? DeletedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the expiration date and time of the group.
        /// </summary>
        public DateTime? ExpirationDateTime { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group can be assigned to a role.
        /// </summary>
        public bool? IsAssignableToRole { get; set; }

        /// <summary>
        /// Gets or sets the membership rule for dynamic group membership.
        /// </summary>
        public string MembershipRule { get; set; }

        /// <summary>
        /// Gets or sets the processing state of the membership rule.
        /// </summary>
        public string MembershipRuleProcessingState { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was last renewed.
        /// </summary>
        public DateTime? RenewedDateTime { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group is security-enabled.
        /// </summary>
        public bool? SecurityEnabled { get; set; }

        /// <summary>
        /// Gets or sets the security identifier (SID) for the group.
        /// </summary>
        public string SecurityIdentifier { get; set; }

        /// <summary>
        /// Gets or sets the resource provisioning options of the group. Contains "Team"
        /// when a Microsoft Teams team is provisioned on top of the group - the reliable
        /// way to tell a team from a plain Microsoft 365 group.
        /// </summary>
        public string[] ResourceProvisioningOptions { get; set; }

        /// <summary>
        /// Gets or sets the list of sensitivity label pairs (label ID, label name) associated with a Microsoft 365 group.
        /// </summary>
        public AssignedLabel[] AssignedLabels { get; set; }

        /// <summary>
        /// Gets or sets the licenses that are assigned to the group.
        /// Returned only on $select. Supports $filter (eq). Read-only.
        /// </summary>
        public AssignedLicense[] AssignedLicenses { get; set; }
    }
}
