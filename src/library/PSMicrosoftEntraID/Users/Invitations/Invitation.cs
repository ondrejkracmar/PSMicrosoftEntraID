using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Users.Invitations
{
    /// <summary>
    /// Represents an invitation resource in Microsoft Graph API.
    /// </summary>
    [DataContract]
    public class Invitation
    {
        /// <summary>
        /// Gets or sets the display name of the invited user.
        /// </summary>
        [DataMember(Name = "invitedUserDisplayName")]
        public string InvitedUserDisplayName { get; set; }

        /// <summary>
        /// Gets or sets the email address of the invited user.
        /// </summary>
        [DataMember(Name = "invitedUserEmailAddress")]
        public string InvitedUserEmailAddress { get; set; }

        /// <summary>
        /// Gets or sets the message information sent to the invited user.
        /// </summary>
        [DataMember(Name = "invitedUserMessageInfo")]
        public InvitedUserMessageInfo InvitedUserMessageInfo { get; set; }

        /// <summary>
        /// Gets or sets the user object of the invited user.
        /// </summary>
        [DataMember(Name = "invitedUser")]
        public User InvitedUser { get; set; }

        /// <summary>
        /// Gets or sets the URL the user can use to redeem their invitation.
        /// </summary>
        [DataMember(Name = "inviteRedeemUrl")]
        public string InviteRedeemUrl { get; set; }

        /// <summary>
        /// Gets or sets the URL the user is redirected to after accepting the invitation.
        /// </summary>
        [DataMember(Name = "inviteRedirectUrl")]
        public string InviteRedirectUrl { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether to send the invitation message.
        /// </summary>
        [DataMember(Name = "sendInvitationMessage")]
        public bool? SendInvitationMessage { get; set; }

        /// <summary>
        /// Gets or sets the status of the invitation.
        /// </summary>
        [DataMember(Name = "status")]
        public string Status { get; set; }

        /// <summary>
        /// Gets or sets the type of the invited user.
        /// </summary>
        [DataMember(Name = "invitedUserType")]
        public string InvitedUserType { get; set; }

        /// <summary>
        /// Gets or sets the phone number of the invited user.
        /// </summary>
        [DataMember(Name = "invitedUserPhoneNumber")]
        public string InvitedUserPhoneNumber { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether to reset redemption.
        /// </summary>
        [DataMember(Name = "resetRedemption")]
        public bool? ResetRedemption { get; set; }

        /// <summary>
        /// Gets or sets the expiration date and time of the invitation.
        /// </summary>
        [DataMember(Name = "expirationDateTime")]
        public string ExpirationDateTime { get; set; }
    }
}