using System;

namespace PSMicrosoftEntraID.Contacts
{
    /// <summary>
    /// Represents an organizational contact in Microsoft Entra ID (formerly Azure AD).
    /// This model reflects the orgContact entity from Microsoft Graph API.
    /// </summary>
    public class Contact
    {
        /// <summary>
        /// Unique identifier of the contact.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Display name of the contact.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// First name (given name) of the contact.
        /// </summary>
        public string GivenName { get; set; }

        /// <summary>
        /// Surname (last name) of the contact.
        /// </summary>
        public string Surname { get; set; }

        /// <summary>
        /// Job title of the contact.
        /// </summary>
        public string JobTitle { get; set; }

        /// <summary>
        /// Email address of the contact.
        /// </summary>
        public string Mail { get; set; }

        /// <summary>
        /// Mail nickname (alias).
        /// </summary>
        public string MailNickname { get; set; }

        /// <summary>
        /// Company name of the contact.
        /// </summary>
        public string CompanyName { get; set; }

        /// <summary>
        /// Department of the contact.
        /// </summary>
        public string Department { get; set; }

        /// <summary>
        /// Business phone numbers.
        /// </summary>
        public string[] BusinessPhones { get; set; }

        /// <summary>
        /// Mobile phone number.
        /// </summary>
        public string MobilePhone { get; set; }

        /// <summary>
        /// Office location of the contact.
        /// </summary>
        public string OfficeLocation { get; set; }

        /// <summary>
        /// Preferred language for communication.
        /// </summary>
        public string PreferredLanguage { get; set; }

        /// <summary>
        /// Proxy addresses associated with the contact.
        /// </summary>
        public string[] ProxyAddresses { get; set; }
    }
}
