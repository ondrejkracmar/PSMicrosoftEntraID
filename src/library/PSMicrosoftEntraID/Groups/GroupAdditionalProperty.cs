using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a group additional property in Microsoft Entra ID.
    /// This class provides properties for group identification, contact information, settings, and membership rules.
    /// </summary>
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
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the email address of the group.
        /// </summary>
        public string Mail { get; set; }

        /// <summary>
        /// Gets or sets the nickname or alias of the group's email.
        /// </summary>
        public string MailNickname { get; set; }

        /// <summary>
        /// Gets or sets the display name of the group.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// True if the group isn't displayed in certain parts of the Outlook UI.
        /// </summary>
        public bool? HideFromAddressLists { get; set; }

        /// <summary>
        /// True if the group isn't displayed in Outlook clients, such as Outlook for Windows and Outlook on the web.
        /// </summary>
        public bool? HideFromOutlookClients { get; set; }

        /// <summary>
        /// Indicates if people external to the organization can send messages to the group.
        /// </summary>
        public bool? AllowExternalSenders { get; set; }

        /// <summary>
        /// Indicates if new members added to the group are autosubscribed to receive email notifications.
        /// </summary>
        public bool? AutoSubscribeNewMembers { get; set; }
    }
}
