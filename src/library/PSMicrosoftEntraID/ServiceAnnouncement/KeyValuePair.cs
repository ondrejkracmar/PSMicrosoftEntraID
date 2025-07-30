using System.Runtime.Serialization;


namespace PSMicrosoftEntraID.ServiceAnnouncement
{
    /// <summary>
    /// Represents a name/value pair used in the details property.
    /// </summary>
    [DataContract]
    public class KeyValuePair
    {
        /// <summary>
        /// Name of the key/value pair.
        /// </summary>
        [DataMember(Name = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Value of the key/value pair.
        /// </summary>
        [DataMember(Name = "value")]
        public string Value { get; set; }
    }
}
