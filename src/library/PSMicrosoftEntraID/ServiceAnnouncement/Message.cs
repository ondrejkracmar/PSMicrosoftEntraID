using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents a single Microsoft 365 Message Center announcement.
    /// </summary>
    [DataContract]
    public class Message
    {
        /// <summary>
        /// Unique identifier of the message.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Title of the message.
        /// </summary>
        [DataMember(Name = "title")]
        public string Title { get; set; }

        /// <summary>
        /// Category of the message (plan, feature, retire, stayInformed).
        /// </summary>
        [DataMember(Name = "category")]
        public string Category { get; set; }

        /// <summary>
        /// Severity of the message (normal, high, critical).
        /// </summary>
        [DataMember(Name = "severity")]
        public string Severity { get; set; }

        /// <summary>
        /// Microsoft 365 services affected by the message.
        /// </summary>
        [DataMember(Name = "services")]
        public string[] Services { get; set; }

        /// <summary>
        /// Tags associated with the message.
        /// </summary>
        [DataMember(Name = "tags")]
        public string[] Tags { get; set; }

        /// <summary>
        /// Indicates whether this is a major change.
        /// </summary>
        [DataMember(Name = "isMajorChange")]
        public bool IsMajorChange { get; set; }

        /// <summary>
        /// Date and time the message was last modified.
        /// </summary>
        [DataMember(Name = "lastModifiedDateTime")]
        public string LastModifiedDateTime { get; set; }

        /// <summary>
        /// Optional date when the message starts to apply.
        /// </summary>
        [DataMember(Name = "startDateTime")]
        public string StartDateTime { get; set; }

        /// <summary>
        /// Optional date when the message ends.
        /// </summary>
        [DataMember(Name = "endDateTime")]
        public string EndDateTime { get; set; }

        /// <summary>
        /// Optional date when action is required by.
        /// </summary>
        [DataMember(Name = "actionRequiredByDateTime")]
        public string ActionRequiredByDateTime { get; set; }

        /// <summary>
        /// Object containing message body details.
        /// </summary>
        [DataMember(Name = "body")]
        public Body Body { get; set; }

        /// <summary>
        /// Object containing user-specific view state.
        /// </summary>
        [DataMember(Name = "viewPoint")]
        public ViewPoint ViewPoint { get; set; }

        /// <summary>
        /// Indicates whether the message has attachments.
        /// </summary>
        [DataMember(Name = "hasAttachments")]
        public bool HasAttachments { get; set; }

        /// <summary>
        /// A stream representing the attachments archive (if present).
        /// </summary>
        [DataMember(Name = "attachmentsArchive")]
        public byte[] AttachmentsArchive { get; set; }

        /// <summary>
        /// Optional array of key-value details.
        /// </summary>
        [DataMember(Name = "details")]
        public KeyValuePair[] Details { get; set; }
    }
}
