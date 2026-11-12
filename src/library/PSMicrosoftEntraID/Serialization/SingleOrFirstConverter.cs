using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PSMicrosoftEntraID.Serialization
{
    /// <summary>
    /// Reads a Graph property that is a single object in some API versions and a collection in others into one
    /// object: the object itself, or the first element of the array (null for an empty array). Writes the object.
    /// Put it on the property with [JsonConverter(typeof(SingleOrFirstConverter&lt;T&gt;))] - a shape mismatch would
    /// otherwise fail the whole page.
    /// </summary>
    /// <typeparam name="T">The model type.</typeparam>
    public sealed class SingleOrFirstConverter<T> : JsonConverter<T>
        where T : class
    {
        /// <summary>Reads an object, an array of objects (first wins) or null.</summary>
        /// <param name="reader">The reader.</param>
        /// <param name="typeToConvert">The type to convert to.</param>
        /// <param name="options">The serializer options.</param>
        /// <returns>The object, or null.</returns>
        public override T Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.Null:
                    return null;
                case JsonTokenType.StartArray:
                    var items = JsonSerializer.Deserialize<T[]>(ref reader, options);
                    return items is { Length: > 0 } ? items[0] : null;
                default:
                    return JsonSerializer.Deserialize<T>(ref reader, options);
            }
        }

        /// <summary>Writes the object.</summary>
        /// <param name="writer">The writer.</param>
        /// <param name="value">The value.</param>
        /// <param name="options">The serializer options.</param>
        public override void Write(Utf8JsonWriter writer, T value, JsonSerializerOptions options)
        {
            ArgumentNullException.ThrowIfNull(writer);
            JsonSerializer.Serialize(writer, value, options);
        }
    }
}
