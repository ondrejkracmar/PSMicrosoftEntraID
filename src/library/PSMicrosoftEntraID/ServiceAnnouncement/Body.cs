namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents the body content of a message.
    /// </summary>
    public class Body
    {
        /// <summary>
        /// Type of content, typically "html".
        /// </summary>
        public string ContentType { get; set; }

        /// <summary>
        /// The raw HTML content.
        /// </summary>
        public string Content { get; set; }
    }
}
