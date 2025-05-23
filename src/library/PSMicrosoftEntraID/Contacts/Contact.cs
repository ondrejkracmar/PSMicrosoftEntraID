using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Contacts
{
    /// <summary>
    /// Represents an organizational contact in Microsoft Entra ID (formerly Azure AD).
    /// This model reflects the orgContact entity from Microsoft Graph API.
    /// </summary>
    [DataContract]
    public class Contact
    {
        /// <summary>
        /// Unique identifier of the contact.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Display name of the contact.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }

        /// <summary>
        /// First name (given name) of the contact.
        /// </summary>
        [DataMember(Name = "givenName")]
        public string GivenName { get; set; }

        /// <summary>
        /// Surname (last name) of the contact.
        /// </summary>
        [DataMember(Name = "surname")]
        public string Surname { get; set; }

        /// <summary>
        /// Job title of the contact.
        /// </summary>
        [DataMember(Name = "jobTitle")]
        public string JobTitle { get; set; }

        /// <summary>
        /// Email address of the contact.
        /// </summary>
        [DataMember(Name = "mail")]
        public string Mail { get; set; }

        /// <summary>
        /// Mail nickname (alias).
        /// </summary>
        [DataMember(Name = "mailNickname")]
        public string MailNickname { get; set; }

        /// <summary>
        /// Company name of the contact.
        /// </summary>
        [DataMember(Name = "companyName")]
        public string CompanyName { get; set; }

        /// <summary>
        /// Department of the contact.
        /// </summary>
        [DataMember(Name = "department")]
        public string Department { get; set; }

        /// <summary>
        /// Business phone numbers.
        /// </summary>
        [DataMember(Name = "businessPhones")]
        public string[] BusinessPhones { get; set; }

        /// <summary>
        /// Mobile phone number.
        /// </summary>
        [DataMember(Name = "mobilePhone")]
        public string MobilePhone { get; set; }

        /// <summary>
        /// Office location of the contact.
        /// </summary>
        [DataMember(Name = "officeLocation")]
        public string OfficeLocation { get; set; }

        /// <summary>
        /// Preferred language for communication.
        /// </summary>
        [DataMember(Name = "preferredLanguage")]
        public string PreferredLanguage { get; set; }

        /// <summary>
        /// Proxy addresses associated with the contact.
        /// </summary>
        [DataMember(Name = "proxyAddresses")]
        public string[] ProxyAddresses { get; set; }
    }
}
