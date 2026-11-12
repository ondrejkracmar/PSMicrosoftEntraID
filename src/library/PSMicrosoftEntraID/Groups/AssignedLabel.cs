namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a sensitivity label assigned to a Microsoft 365 group, as per Microsoft Graph API.
    /// </summary>
    public class AssignedLabel
    {
        /// <summary>
        /// Gets or sets the unique identifier of the label.
        /// </summary>
        public string LabelId { get; set; }

        /// <summary>
        /// Gets or sets the display name of the label.
        /// </summary>
        public string DisplayName { get; set; }
    }
}