using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using PSMicrosoftEntraID.Delta;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// A single membership change reported by a group delta query.
    /// </summary>
    /// <remarks>
    /// Graph's "members@delta" carries only what is needed to apply the change: the id
    /// of the member, its type, and whether it was added or removed. It does not send
    /// the member object itself - resolve it separately if the details matter.
    /// </remarks>
    public class GroupMemberDelta
    {
        /// <summary>
        /// The identifier of the member that was added or removed.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// The kind of directory object, as Graph's "@odata.type" reports it -
        /// for example #microsoft.graph.user or #microsoft.graph.group.
        /// </summary>
        [JsonPropertyName("@odata.type")]
        public string ObjectType { get; set; }

        /// <summary>
        /// True when the member left the group, false when it joined.
        /// </summary>
        public bool Removed { get; set; }

        /// <summary>
        /// Receives the "@removed" annotation Graph puts on a member that left (a string such as "deleted" or an
        /// object with a reason) and sets <see cref="Removed"/>. Write-only by design: never written back.
        /// </summary>
        [JsonInclude]
        [JsonPropertyName("@removed")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        internal JsonElement? RemovedAnnotation
        {
            get { return null; }
            set { Removed = DeltaAnnotation.IsPresent(value); }
        }

        /// <summary>
        /// Reads as "+ &lt;id&gt;" for a member that joined and "- &lt;id&gt;" for one that left.
        /// </summary>
        public override string ToString()
        {
            return string.Format("{0} {1}", Removed ? "-" : "+", Id);
        }
    }
}
