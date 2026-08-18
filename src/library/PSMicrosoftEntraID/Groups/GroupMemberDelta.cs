using System;
using System.Runtime.Serialization;

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
    [DataContract]
    public class GroupMemberDelta
    {
        /// <summary>
        /// The identifier of the member that was added or removed.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// The kind of directory object, as Graph's "@odata.type" reports it -
        /// for example #microsoft.graph.user or #microsoft.graph.group.
        /// </summary>
        [DataMember(Name = "@odata.type")]
        public string ObjectType { get; set; }

        /// <summary>
        /// True when the member left the group, false when it joined.
        /// </summary>
        public bool Removed { get; set; }

        /// <summary>
        /// Reads as "+ &lt;id&gt;" for a member that joined and "- &lt;id&gt;" for one that left.
        /// </summary>
        public override string ToString()
        {
            return string.Format("{0} {1}", Removed ? "-" : "+", Id);
        }
    }
}
