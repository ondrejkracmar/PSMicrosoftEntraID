using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a group in Microsoft Entra ID.
    /// This class provides properties for group identification, contact information, settings, and membership rules.
    /// </summary>
    [DataContract]
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
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was created.
        /// </summary>
        [DataMember(Name = "createdDateTime")]
        public string CreatedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the email address of the group.
        /// </summary>
        [DataMember(Name = "mail")]
        public string Mail { get; set; }

        /// <summary>
        /// Gets or sets the nickname or alias of the group's email.
        /// </summary>
        [DataMember(Name = "mailNickname")]
        public string MailNickname { get; set; }

        /// <summary>
        /// Gets or sets the collection of proxy addresses for the group.
        /// </summary>
        [DataMember(Name = "proxyAddresses")]
        public string[] ProxyAddresses { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group is mail-enabled.
        /// </summary>
        [DataMember(Name = "mailEnabled")]
        public bool? MailEnabled { get; set; }

        /// <summary>
        /// Gets or sets the visibility of the group.
        /// </summary>
        [DataMember(Name = "visibility")]
        public string Visibility { get; set; }

        /// <summary>
        /// Gets or sets the display name of the group.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// Gets or sets the description of the group.
        /// </summary>
        [DataMember(Name = "description")]
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the types of the group.
        /// </summary>
        [DataMember(Name = "gropupTypes")]
        public string[] GropupTypes { get; set; }

        /// <summary>
        /// Gets or sets the creation options for the group.
        /// </summary>
        [DataMember(Name = "creationOptions")]
        public string[] CreationOptions { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was deleted.
        /// </summary>
        [DataMember(Name = "deletedDateTime")]
        public string DeletedDateTime { get; set; }

        /// <summary>
        /// Gets or sets the expiration date and time of the group.
        /// </summary>
        [DataMember(Name = "expirationDateTime")]
        public string ExpirationDateTime { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group can be assigned to a role.
        /// </summary>
        [DataMember(Name = "isAssignableToRole")]
        public bool? IsAssignableToRole { get; set; }

        /// <summary>
        /// Gets or sets the membership rule for dynamic group membership.
        /// </summary>
        [DataMember(Name = "membershipRule")]
        public string MembershipRule { get; set; }

        /// <summary>
        /// Gets or sets the processing state of the membership rule.
        /// </summary>
        [DataMember(Name = "membershipRuleProcessingState")]
        public string MembershipRuleProcessingState { get; set; }

        /// <summary>
        /// Gets or sets the date and time when the group was last renewed.
        /// </summary>
        [DataMember(Name = "renewedDateTime")]
        public string RenewedDateTime { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the group is security-enabled.
        /// </summary>
        [DataMember(Name = "securityEnabled")]
        public bool? SecurityEnabled { get; set; }

        /// <summary>
        /// Gets or sets the security identifier (SID) for the group.
        /// </summary>
        [DataMember(Name = "securityIdentifier")]
        public string SecurityIdentifier { get; set; }

        /// <summary>
        /// True if the group isn't displayed in certain parts of the Outlook UI.
        /// </summary>
        [DataMember(Name = "hideFromAddressLists")]
        #nullable enable
        public Boolean? HideFromAddressLists { get; set; }

        /// <summary>
        /// True if the group isn't displayed in Outlook clients, such as Outlook for Windows and Outlook on the web.
        /// </summary>
        [DataMember(Name = "hideFromOutlookClients")]
        #nullable enable
        public Boolean? HideFromOutlookClients { get; set; }

        /// <summary>
        /// Indicates if people external to the organization can send messages to the group.
        /// </summary>
        [DataMember(Name = "allowExternalSenders")]
        #nullable enable
        public string? AllowExternalSenders { get; set; }

        /// <summary>
        /// Indicates if new members added to the group are autosubscribed to receive email notifications.
        /// </summary>
        [DataMember(Name = "autoSubscribeNewMembers")]
        #nullable enable
        public string? AutoSubscribeNewMembers { get; set; }
    }
}
