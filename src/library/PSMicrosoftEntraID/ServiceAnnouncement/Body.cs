using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents the body content of a message.
    /// </summary>
    [DataContract]
    public class Body
    {
        /// <summary>
        /// Type of content, typically "html".
        /// </summary>
        [DataMember(Name = "contentType")]
        public string ContentType { get; set; }

        /// <summary>
        /// The raw HTML content.
        /// </summary>
        [DataMember(Name = "content")]
        public string Content { get; set; }
    }
}
