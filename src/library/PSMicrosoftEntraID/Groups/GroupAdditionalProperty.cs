using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a group additional property in Microsoft Entra ID.
    /// This class provides properties for group identification, contact information, settings, and membership rules.
    /// </summary>
    [DataContract]
    public class GroupAdditionalProperty
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="GroupAdditionalProperty"/> class.
        /// </summary>
        public GroupAdditionalProperty()
        {
        }

        /// <summary>
        /// Gets or sets the unique identifier of the group.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

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
        /// Gets or sets the display name of the group.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

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
