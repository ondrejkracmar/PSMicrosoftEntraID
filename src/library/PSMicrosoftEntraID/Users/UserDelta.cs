using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using PSMicrosoftEntraID.Delta;

namespace PSMicrosoftEntraID.Users
{
    /// <summary>
    /// A user as returned by a delta query, carrying what happened to it since the
    /// previous call.
    /// </summary>
    /// <remarks>
    /// Everything the base type exposes is still here; a delta response simply adds the
    /// change annotation. Objects Graph reports as removed arrive with only their id
    /// populated - Graph does not resend the rest for something that is gone.
    /// </remarks>
    public class UserDelta : User
    {
        /// <summary>
        /// True when this object was removed rather than changed. Shorthand for
        /// ChangeType being anything other than Changed.
        /// </summary>
        public bool Removed
        {
            get { return ChangeType != DeltaChangeType.Changed; }
        }

        /// <summary>
        /// What happened to the object since the previous delta call.
        /// </summary>
        public DeltaChangeType ChangeType { get; set; }

        /// <summary>
        /// Receives Graph's "@removed" annotation while the object is deserialized and turns it into
        /// <see cref="ChangeType"/>. Write-only by design: the annotation itself is not kept, and it is never
        /// written back.
        /// </summary>
        [JsonInclude]
        [JsonPropertyName("@removed")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        internal JsonElement? RemovedAnnotation
        {
            get { return null; }
            set { ChangeType = DeltaAnnotation.ToChangeType(value); }
        }

        /// <summary>
        /// Prefixes the object's description with the change, so a removed object is not
        /// mistaken for a live one in console output.
        /// </summary>
        /// <remarks>
        /// Only Device overrides ToString among the base types; for the rest base.ToString()
        /// would just print the class name, so fall back to the identifier - which is the
        /// one field a removed object is guaranteed to carry.
        /// </remarks>
        public override string ToString()
        {
            string description = base.ToString();
            if (string.IsNullOrWhiteSpace(description) || description == GetType().FullName)
            {
                description = Id;
            }
            return string.Format("[{0}] {1}", ChangeType, description);
        }
    }
}
