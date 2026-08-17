using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Users
{
    /// <summary>
    /// Represents an identity used to sign in to a user account, as returned in the
    /// <c>identities</c> collection of the Microsoft Graph <c>user</c> resource.
    /// An identity can be provided by Microsoft, by an organization, or by a social
    /// identity provider such as Facebook or Google.
    /// </summary>
    /// <remarks>
    /// Mirrors https://learn.microsoft.com/en-us/graph/api/resources/objectidentity
    /// (Microsoft Graph v1.0). The resource has exactly these three properties.
    /// </remarks>
    [DataContract]
    public class ObjectIdentity
    {
        /// <summary>
        /// The sign-in type of the identity, such as <c>emailAddress</c>, <c>userName</c>,
        /// <c>federated</c> or <c>userPrincipalName</c>. <c>federated</c> means the
        /// identifier comes from an external issuer in a format that issuer chose. Any
        /// custom string is also allowed.
        /// </summary>
        [DataMember(Name = "signInType")]
        public string SignInType { get; set; }

        /// <summary>
        /// The issuer of the identity - for a local account the tenant's default domain
        /// (for example <c>contoso.onmicrosoft.com</c>), for a guest from another Entra
        /// organization the domain of that organization, for a social account the provider
        /// (for example <c>facebook.com</c>). 512 character limit.
        /// </summary>
        [DataMember(Name = "issuer")]
        public string Issuer { get; set; }

        /// <summary>
        /// The identifier the issuer assigned to the user. The combination of
        /// <see cref="Issuer"/> and this value is unique within the organization.
        /// 64 character limit.
        /// </summary>
        [DataMember(Name = "issuerAssignedId")]
        public string IssuerAssignedId { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ObjectIdentity"/> class.
        /// </summary>
        public ObjectIdentity() { }

        /// <summary>
        /// Renders the identity as <c>signInType:issuer/issuerAssignedId</c>, so a
        /// collection of them stays readable when a user object is formatted as a table.
        /// </summary>
        public override string ToString()
        {
            return string.Format("{0}:{1}/{2}", SignInType, Issuer, IssuerAssignedId);
        }
    }
}
