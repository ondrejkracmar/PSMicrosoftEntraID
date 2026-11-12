using System;
using System.Text.Json;
using System.Text.Json.Serialization;
using PSMicrosoftEntraID.Resources;

namespace PSMicrosoftEntraID.Serialization
{
    /// <summary>
    /// Converts Microsoft Graph JSON into the typed objects of this module with System.Text.Json, straight from the
    /// JSON text - no PowerShell objects in between and no depth limit of ConvertTo-Json.
    /// Property names match case-insensitively and unknown properties (such as @odata.etag) are ignored, so a Graph
    /// response can be deserialized whatever $select returned. System.Text.Json does not read [DataMember(Name)]: a
    /// model property is matched by its own name (ignoring case) or by [JsonPropertyName].
    /// </summary>
    public static class GraphJson
    {
        private static readonly JsonSerializerOptions Options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            NumberHandling = JsonNumberHandling.AllowReadingFromString,
            UnmappedMemberHandling = JsonUnmappedMemberHandling.Skip,
        };

        /// <summary>
        /// Deserializes one JSON object into an instance of <paramref name="type"/>.
        /// </summary>
        /// <param name="json">The JSON text of a single Graph object.</param>
        /// <param name="type">The target type.</param>
        /// <returns>The deserialized object.</returns>
        /// <exception cref="ArgumentException">The JSON is empty.</exception>
        public static object Deserialize(string json, Type type)
        {
            ArgumentNullException.ThrowIfNull(type);
            if (string.IsNullOrWhiteSpace(json))
            {
                throw new ArgumentException(Strings.JsonEmpty, nameof(json));
            }

            return JsonSerializer.Deserialize(json, type, Options);
        }

        /// <summary>
        /// Deserializes the items of a Graph response straight from its JSON text: the "value" array of a collection
        /// page, a bare JSON array, or a single object (returned as an array of one).
        /// Used by the batch engine so a page never becomes PowerShell objects before it becomes typed objects.
        /// </summary>
        /// <param name="json">The JSON text of a Graph response body.</param>
        /// <param name="elementType">The type of one item.</param>
        /// <returns>An array of <paramref name="elementType"/>; empty when the body holds no items.</returns>
        /// <exception cref="ArgumentException">The JSON is empty.</exception>
        public static Array DeserializeCollection(string json, Type elementType)
        {
            ArgumentNullException.ThrowIfNull(elementType);
            if (string.IsNullOrWhiteSpace(json))
            {
                throw new ArgumentException(Strings.JsonEmpty, nameof(json));
            }

            var arrayType = elementType.MakeArrayType();
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;
            if (root.ValueKind == JsonValueKind.Object)
            {
                foreach (var property in root.EnumerateObject())
                {
                    if (string.Equals(property.Name, "value", StringComparison.OrdinalIgnoreCase) && property.Value.ValueKind == JsonValueKind.Array)
                    {
                        return (Array)property.Value.Deserialize(arrayType, Options) ?? Array.CreateInstance(elementType, 0);
                    }
                }

                var single = root.Deserialize(elementType, Options);
                var one = Array.CreateInstance(elementType, single is null ? 0 : 1);
                if (single is not null)
                {
                    one.SetValue(single, 0);
                }

                return one;
            }

            if (root.ValueKind == JsonValueKind.Array)
            {
                return (Array)root.Deserialize(arrayType, Options) ?? Array.CreateInstance(elementType, 0);
            }

            return Array.CreateInstance(elementType, 0);
        }
    }
}
