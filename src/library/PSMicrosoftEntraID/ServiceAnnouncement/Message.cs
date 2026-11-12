using System;

namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents a single Microsoft 365 Message Center announcement.
    /// </summary>
    public class Message
    {
        /// <summary>
        /// Unique identifier of the message.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Title of the message.
        /// </summary>
        public string Title { get; set; }

        /// <summary>
        /// Category of the message (plan, feature, retire, stayInformed).
        /// </summary>
        public string Category { get; set; }

        /// <summary>
        /// Severity of the message (normal, high, critical).
        /// </summary>
        public string Severity { get; set; }

        /// <summary>
        /// Microsoft 365 services affected by the message.
        /// </summary>
        public string[] Services { get; set; }

        /// <summary>
        /// Tags associated with the message.
        /// </summary>
        public string[] Tags { get; set; }

        /// <summary>
        /// Indicates whether this is a major change.
        /// </summary>
        public bool? IsMajorChange { get; set; }

        /// <summary>
        /// Date and time the message was last modified.
        /// </summary>
        public DateTime? LastModifiedDateTime { get; set; }

        /// <summary>
        /// Optional date when the message starts to apply.
        /// </summary>
        public DateTime? StartDateTime { get; set; }

        /// <summary>
        /// Optional date when the message ends.
        /// </summary>
        public DateTime? EndDateTime { get; set; }

        /// <summary>
        /// Optional date when action is required by.
        /// </summary>
        public DateTime? ActionRequiredByDateTime { get; set; }

        /// <summary>
        /// Object containing message body details.
        /// </summary>
        public Body Body { get; set; }

        /// <summary>
        /// Object containing user-specific view state.
        /// </summary>
        public ViewPoint ViewPoint { get; set; }

        /// <summary>
        /// Indicates whether the message has attachments.
        /// </summary>
        public bool? HasAttachments { get; set; }

        /// <summary>
        /// A stream representing the attachments archive (if present).
        /// </summary>
        public byte[] AttachmentsArchive { get; set; }

        /// <summary>
        /// Optional array of key-value details.
        /// </summary>
        public KeyValuePair[] Details { get; set; }
    }
}
