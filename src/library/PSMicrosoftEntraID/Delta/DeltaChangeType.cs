using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Delta
{
    /// <summary>
    /// What a delta response says happened to an object since the previous call.
    /// </summary>
    /// <remarks>
    /// Graph marks a vanished object with an "@removed" annotation carrying a reason,
    /// and says nothing at all for one that merely changed. Turning that into an
    /// explicit value means a caller can switch on it instead of testing for the
    /// presence of an annotation.
    /// </remarks>
    [DataContract]
    public enum DeltaChangeType
    {
        /// <summary>
        /// The object was created or updated. Graph sends the object with no "@removed".
        /// </summary>
        [EnumMember(Value = "changed")]
        Changed = 0,

        /// <summary>
        /// The object was soft-deleted and can still be restored
        /// ("@removed" with reason "changed").
        /// </summary>
        [EnumMember(Value = "deleted")]
        Deleted = 1,

        /// <summary>
        /// The object was permanently removed, or moved out of the scope being tracked
        /// ("@removed" with reason "deleted").
        /// </summary>
        [EnumMember(Value = "purged")]
        Purged = 2
    }
}
