using System;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PSMicrosoftEntraID.Serialization
{
    /// <summary>
    /// Reads a Graph property that is a plain string in some API versions and an object wrapping the string in
    /// "value" in others, and any other JSON value (a number, a boolean, an array) as its raw text. Writes it back as a
    /// plain string. Put it on a string property with [JsonConverter(typeof(StringOrValueConverter))].
    /// </summary>
    public sealed class StringOrValueConverter : JsonConverter<string>
    {
        /// <summary>Reads a string, an object with a "value" member, null, or any other value as its raw text.</summary>
        /// <param name="reader">The reader.</param>
        /// <param name="typeToConvert">The type to convert to (string).</param>
        /// <param name="options">The serializer options.</param>
        /// <returns>The text.</returns>
        public override string Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.Null:
                    return null;
                case JsonTokenType.String:
                    return reader.GetString();
                case JsonTokenType.StartObject:
                    using (var document = JsonDocument.ParseValue(ref reader))
                    {
                        foreach (var property in document.RootElement.EnumerateObject())
                        {
                            if (string.Equals(property.Name, "value", StringComparison.OrdinalIgnoreCase))
                            {
                                return property.Value.ValueKind == JsonValueKind.String ? property.Value.GetString() : property.Value.GetRawText();
                            }
                        }
                    }

                    return null;
                default:
                    using (var document = JsonDocument.ParseValue(ref reader))
                    {
                        return document.RootElement.GetRawText();
                    }
            }
        }

        /// <summary>Writes the value as a plain string.</summary>
        /// <param name="writer">The writer.</param>
        /// <param name="value">The value.</param>
        /// <param name="options">The serializer options.</param>
        public override void Write(Utf8JsonWriter writer, string value, JsonSerializerOptions options)
        {
            ArgumentNullException.ThrowIfNull(writer);
            if (value is null)
            {
                writer.WriteNullValue();
                return;
            }

            writer.WriteStringValue(value);
        }
    }
}
