using System;

namespace PSMicrosoftEntraID.Users.Invitations
{
    /// <summary>
    /// Represents an invitation resource in Microsoft Graph API.
    /// </summary>
    public class Invitation
    {
        /// <summary>
        /// Gets or sets the display name of the invited user.
        /// </summary>
        public string InvitedUserDisplayName { get; set; }

        /// <summary>
        /// Gets or sets the email address of the invited user.
        /// </summary>
        public string InvitedUserEmailAddress { get; set; }

        /// <summary>
        /// Gets or sets the message information sent to the invited user.
        /// </summary>
        public InvitedUserMessageInfo InvitedUserMessageInfo { get; set; }

        /// <summary>
        /// Gets or sets the user object of the invited user.
        /// </summary>
        public User InvitedUser { get; set; }

        /// <summary>
        /// Gets or sets the URL the user can use to redeem their invitation.
        /// </summary>
        public string InviteRedeemUrl { get; set; }

        /// <summary>
        /// Gets or sets the URL the user is redirected to after accepting the invitation.
        /// </summary>
        public string InviteRedirectUrl { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether to send the invitation message.
        /// </summary>
        public bool? SendInvitationMessage { get; set; }

        /// <summary>
        /// Gets or sets the status of the invitation.
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// Gets or sets the type of the invited user.
        /// </summary>
        public string InvitedUserType { get; set; }

        /// <summary>
        /// Gets or sets the phone number of the invited user.
        /// </summary>
        public string InvitedUserPhoneNumber { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether to reset redemption.
        /// </summary>
        public bool? ResetRedemption { get; set; }

        /// <summary>
        /// Gets or sets the expiration date and time of the invitation.
        /// </summary>
        public DateTime? ExpirationDateTime { get; set; }
    }
}