using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Users.Invitations
{
    /// <summary>
    /// Represents the message information sent to the invited user, as per Microsoft Graph API.
    /// </summary>
    [DataContract]
    public class InvitedUserMessageInfo
    {
        /// <summary>
        /// Gets or sets the customized message body sent to the invited user.
        /// </summary>
        [DataMember(Name = "customizedMessageBody")]
        public string CustomizedMessageBody { get; set; }

        /// <summary>
        /// Gets or sets the language of the message.
        /// </summary>
        [DataMember(Name = "messageLanguage")]
        public string MessageLanguage { get; set; }
    }
}