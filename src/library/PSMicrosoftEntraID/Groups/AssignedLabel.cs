using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// Represents a sensitivity label assigned to a Microsoft 365 group, as per Microsoft Graph API.
    /// </summary>
    [DataContract]
    public class AssignedLabel
    {
        /// <summary>
        /// Gets or sets the unique identifier of the label.
        /// </summary>
        [DataMember(Name = "labelId")]
        public string LabelId { get; set; }

        /// <summary>
        /// Gets or sets the display name of the label.
        /// </summary>
        [DataMember(Name = "displayName")]
        public string DisplayName { get; set; }
    }
}