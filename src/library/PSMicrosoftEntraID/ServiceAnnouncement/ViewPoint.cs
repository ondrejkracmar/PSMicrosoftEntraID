using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents the view-related properties of a message.
    /// </summary>
    [DataContract]
    public class ViewPoint
    {
        /// <summary>
        /// Indicates whether the message is marked as read.
        /// </summary>
        [DataMember(Name = "isRead")]
        public bool IsRead { get; set; }

        /// <summary>
        /// Indicates whether the message is archived.
        /// </summary>
        [DataMember(Name = "isArchived")]
        public bool IsArchived { get; set; }

        /// <summary>
        /// Indicates whether the message is marked as favorite.
        /// </summary>
        [DataMember(Name = "isFavorited")]
        public bool IsFavorited { get; set; }
    }
}
