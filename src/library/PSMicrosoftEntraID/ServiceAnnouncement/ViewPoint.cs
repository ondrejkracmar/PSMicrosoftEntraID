namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents the view-related properties of a message.
    /// </summary>
    public class ViewPoint
    {
        /// <summary>
        /// Indicates whether the message is marked as read.
        /// </summary>
        public bool? IsRead { get; set; }

        /// <summary>
        /// Indicates whether the message is archived.
        /// </summary>
        public bool? IsArchived { get; set; }

        /// <summary>
        /// Indicates whether the message is marked as favorite.
        /// </summary>
        public bool? IsFavorited { get; set; }
    }
}
