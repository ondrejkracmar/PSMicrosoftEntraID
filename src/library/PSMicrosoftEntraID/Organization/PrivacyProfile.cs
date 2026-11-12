namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// The privacy profile of an organization (Graph type privacyProfile): who to contact about privacy and where
    /// the privacy statement is published.
    /// </summary>
    public class PrivacyProfile
    {
        /// <summary>
        /// A valid smtp email address for the privacy statement contact.
        /// </summary>
        public string ContactEmail { get; set; }

        /// <summary>
        /// A valid URL format that begins with http:// or https://, the organization's privacy statement.
        /// </summary>
        public string StatementUrl { get; set; }

        /// <summary>
        /// Returns the statement URL, or the contact email when no URL is set.
        /// </summary>
        /// <returns>A short description for console output.</returns>
        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(StatementUrl) ? ContactEmail ?? string.Empty : StatementUrl;
        }
    }
}
