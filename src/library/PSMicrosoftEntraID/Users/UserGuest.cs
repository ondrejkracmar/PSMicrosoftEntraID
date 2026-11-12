using System;
using System.Linq;

namespace PSMicrosoftEntraID.Users
{
    /// <summary>
    /// Represents a Guest user in Microsoft Entra ID (formerly Azure AD).
    /// This class extends the User class and includes additional properties 
    /// related to Guest user invitations.
    /// </summary>
    public class UserGuest : User
    {
        /// <summary>
        /// The external state of the user (e.g., PendingAcceptance, Accepted).
        /// </summary>
        public string ExternalUserState { get; set; }

        /// <summary>
        /// The date and time when the external user state last changed.
        /// </summary>
        public DateTime? ExternalUserStateChangeDateTime { get; set; }

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
        /// The issuer the guest actually signs in with - the home organization's domain
        /// for a B2B guest, or the social provider for a social one. Taken from the first
        /// identity of sign-in type <c>federated</c>, which is where Entra records the
        /// external issuer; the remaining identities describe the local account and name
        /// this tenant instead. Null when the account carries no federated identity, and
        /// when <c>identities</c> was not selected.
        /// </summary>
        public string HomeIssuer
        {
            get
            {
                if (Identities == null) { return null; }

                return Identities
                    .Where(identity => identity != null)
                    .Where(identity => "federated".Equals(identity.SignInType, StringComparison.OrdinalIgnoreCase))
                    .Select(identity => identity.Issuer)
                    .FirstOrDefault();
            }
        }

        /// <summary>
        /// The distinct sign-in types recorded on the account, in the order Graph returned
        /// them. Empty when <c>identities</c> was not selected.
        /// </summary>
        public string[] SignInTypes
        {
            get
            {
                if (Identities == null) { return new string[0]; }

                return Identities
                    .Where(identity => identity != null && !string.IsNullOrEmpty(identity.SignInType))
                    .Select(identity => identity.SignInType)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToArray();
            }
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserGuest"/> class.
        /// </summary>
        public UserGuest() : base() { }
    }
}
