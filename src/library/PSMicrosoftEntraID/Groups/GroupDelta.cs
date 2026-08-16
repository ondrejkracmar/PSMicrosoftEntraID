using System;
using System.Runtime.Serialization;
using PSMicrosoftEntraID.Delta;

namespace PSMicrosoftEntraID.Groups
{
    /// <summary>
    /// A group as returned by a delta query, carrying what happened to it since the
    /// previous call.
    /// </summary>
    /// <remarks>
    /// Everything the base type exposes is still here; a delta response simply adds the
    /// change annotation. Objects Graph reports as removed arrive with only their id
    /// populated - Graph does not resend the rest for something that is gone.
    /// </remarks>
    [DataContract]
    public class GroupDelta : Group
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
        [DataMember(Name = "changeType")]
        public DeltaChangeType ChangeType { get; set; }

        /// <summary>
        /// Membership changes on this group since the previous delta call, from Graph's
        /// "members@delta" annotation. Null when the group's membership did not change.
        /// </summary>
        /// <remarks>
        /// This is what makes group delta worth having for licensing: it answers "who
        /// joined or left this group" without re-reading the whole membership.
        /// </remarks>
        [DataMember(Name = "members@delta")]
        public GroupMemberDelta[] MembersDelta { get; set; }

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
