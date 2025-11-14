using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using PSMicrosoftEntraID.Users.LicenseManagement;

namespace PSMicrosoftEntraID.Users
{
    /// <summary>
    /// Represents a user in Microsoft Entra ID (formerly Azure AD).
    /// This class provides properties to hold user profile, contact information,
    /// and licensing details.
    /// </summary>
    [DataContract]
    public class User
    {
        /// <summary>
        /// The unique identifier of the user.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// The user principal name (UPN) used as the login name.
        /// </summary>
        [DataMember(Name = "userPrincipalName")]
        public string UserPrincipalName { get; set; }

        /// <summary>
        /// The date and time the user was created.
        /// </summary>
        [DataMember(Name = "createdDateTime")]
        public string CreatedDateTime { get; set; }

        /// <summary>
        /// The email address of the user.
        /// </summary>
        [DataMember(Name = "mail")]
        public string Mail { get; set; }

        /// <summary>
        /// The nickname or alias used in the user's email.
        /// </summary>
        [DataMember(Name = "mailNickname")]
        public string MailNickname { get; set; }

        /// <summary>
        /// A collection of proxy addresses associated with the user.
        /// </summary>
        [DataMember(Name = "proxyAddresses")]
        public string[] ProxyAddresses { get; set; }

        /// <summary>
        /// The type of user, such as "Member" or "Guest".
        /// </summary>
        [DataMember(Name = "userType")]
        public string UserType { get; set; }

        /// <summary>
        /// Indicates if the user account is enabled.
        /// </summary>
        [DataMember(Name = "accountEnabled")]
        public bool AccountEnabled { get; set; }

        /// <summary>
        /// The first name of the user.
        /// </summary>
        [DataMember(Name = "givenName")]
        public string GivenName { get; set; }

        /// <summary>
        /// The last name (surname) of the user.
        /// </summary>
        [DataMember(Name = "surname")]
        public string Surname { get; set; }

        /// <summary>
        /// The display name of the user, shown in the UI.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// The employee ID associated with the user.
        /// </summary>
        [DataMember(Name = "employeeId")]
        public string EmployeeId { get; set; }

        /// <summary>
        /// The job title of the user.
        /// </summary>
        [DataMember(Name = "jobTitle")]
        public string JobTitle { get; set; }

        /// <summary>
        /// The department where the user works.
        /// </summary>
        [DataMember(Name = "department")]
        public string Department { get; set; }

        /// <summary>
        /// The office location of the user.
        /// </summary>
        [DataMember(Name = "officeLocation")]
        public string OfficeLocation { get; set; }

        /// <summary>
        /// The company name associated with the user.
        /// </summary>
        [DataMember(Name = "companyName")]
        public string CompanyName { get; set; }

        /// <summary>
        /// The city where the user is located.
        /// </summary>
        [DataMember(Name = "city")]
        public string City { get; set; }

        /// <summary>
        /// The postal code of the user's location.
        /// </summary>
        [DataMember(Name = "postalCode")]
        public string PostalCode { get; set; }

        /// <summary>
        /// The country where the user is located.
        /// </summary>
        [DataMember(Name = "country")]
        public string Country { get; set; }

        /// <summary>
        /// The usage location of the user, used for licensing purposes.
        /// </summary>
        [DataMember(Name = "usageLocation")]
        public string UsageLocation { get; set; }

        /// <summary>
        /// The mobile phone number of the user.
        /// </summary>
        [DataMember(Name = "mobilePhone")]
        public string MobilePhone { get; set; }

        /// <summary>
        /// A collection of business phone numbers for the user.
        /// </summary>
        [DataMember(Name = "businessPhones")]
        public string[] BusinessPhones { get; set; }

        /// <summary>
        /// The fax number associated with the user.
        /// </summary>
        [DataMember(Name = "faxNumber")]
        public string FaxNumber { get; set; }

        /// <summary>
        /// The licenses assigned to the user.
        /// </summary>
        [DataMember(Name = "assignedLicenses")]
        public AssignedLicense[] AssignedLicenses { get; set; }

        /// <summary>
        /// A list of other email addresses for the user; for example: ["bob@contoso.com", "Robert@fabrikam.com"].
        /// Can store up to250 values, each with a limit of250 characters. This property can't contain accent characters.
        /// Returned only on $select. Supports $filter (eq, not, ge, le, in, startsWith, endsWith, /$count eq0, /$count).
        /// </summary>
        [DataMember(Name = "otherMails")]
        public string[] OtherMails { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="User"/> class.
        /// </summary>
        public User() { }
    }
}
