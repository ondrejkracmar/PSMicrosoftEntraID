using System;
using System.Text.Json;

namespace PSMicrosoftEntraID.Delta
{
    /// <summary>
    /// Reads Graph's "@removed" delta annotation.
    /// </summary>
    /// <remarks>
    /// A changed object carries no annotation at all, so "changed" is the absence of information; a vanished one
    /// carries "@removed" whose reason is confusingly named: reason "changed" means soft-deleted (still
    /// restorable, <see cref="DeltaChangeType.Deleted"/>), reason "deleted" means gone for good
    /// (<see cref="DeltaChangeType.Purged"/>). A member inside "members@delta" carries the annotation as a plain
    /// string or an object; for a member only its presence matters.
    /// </remarks>
    internal static class DeltaAnnotation
    {
        /// <summary>Whether the annotation is present (anything but a missing value or JSON null).</summary>
        /// <param name="annotation">The "@removed" value.</param>
        /// <returns>True when the object or member was removed.</returns>
        internal static bool IsPresent(JsonElement? annotation)
        {
            return annotation.HasValue
                && annotation.Value.ValueKind != JsonValueKind.Undefined
                && annotation.Value.ValueKind != JsonValueKind.Null;
        }

        /// <summary>Maps the annotation onto <see cref="DeltaChangeType"/>.</summary>
        /// <param name="annotation">The "@removed" value: an object with a "reason", a plain reason string, or null.</param>
        /// <returns>Changed without an annotation, Purged for reason "deleted", Deleted otherwise.</returns>
        internal static DeltaChangeType ToChangeType(JsonElement? annotation)
        {
            if (!IsPresent(annotation))
            {
                return DeltaChangeType.Changed;
            }

            string reason = null;
            var value = annotation.Value;
            if (value.ValueKind == JsonValueKind.Object)
            {
                foreach (var property in value.EnumerateObject())
                {
                    if (string.Equals(property.Name, "reason", StringComparison.OrdinalIgnoreCase) && property.Value.ValueKind == JsonValueKind.String)
                    {
                        reason = property.Value.GetString();
                        break;
                    }
                }
            }
            else if (value.ValueKind == JsonValueKind.String)
            {
                reason = value.GetString();
            }

            return string.Equals(reason, "deleted", StringComparison.OrdinalIgnoreCase) ? DeltaChangeType.Purged : DeltaChangeType.Deleted;
        }
    }
}
