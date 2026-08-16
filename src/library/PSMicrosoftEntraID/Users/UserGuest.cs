using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Users
{
    /// <summary>
    /// Represents a Guest user in Microsoft Entra ID (formerly Azure AD).
    /// This class extends the User class and includes additional properties 
    /// related to Guest user invitations.
    /// </summary>
    [DataContract]
    public class UserGuest : User
    {
        /// <summary>
        /// The external state of the user (e.g., PendingAcceptance, Accepted).
        /// </summary>
        [DataMember(Name = "externalUserState")]
        public string ExternalUserState { get; set; }

        /// <summary>
        /// The date and time when the external user state last changed.
        /// </summary>
        [DataMember(Name = "externalUserStateChangeDateTime")]
        public string ExternalUserStateChangeDateTime { get; set; }

        /// <summary>
        /// A derived property that represents the invitation status.
        /// Returns "Pending" if the user has not accepted the invitation,
        /// otherwise "Accepted".
        /// </summary>
        public string InvitationStatus
        {
            get
            {
                return ExternalUserState?.Equals("Accepted", StringComparison.OrdinalIgnoreCase) == true
                    ? "Accepted"
                    : "Pending";
            }
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserGuest"/> class.
        /// </summary>
        public UserGuest() : base() { }
    }
}
