using System;
using System.Collections.Generic;
using System.Text.Json;
using PSMicrosoftEntraID.Resources;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Reads the raw JSON of a Graph $batch response without building PowerShell objects.
    /// </summary>
    public static class GraphBatchReader
    {
        /// <summary>
        /// Splits a $batch response into its sub-responses.
        /// </summary>
        /// <param name="json">The response text of POST /$batch.</param>
        /// <returns>One entry per sub-response, in the order Graph returned them.</returns>
        /// <exception cref="ArgumentException">The text is empty or has no "responses" array.</exception>
        public static BatchSubResponse[] Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                throw new ArgumentException(Strings.JsonEmpty, nameof(json));
            }

            using var document = JsonDocument.Parse(json);
            if (!TryGetProperty(document.RootElement, "responses", out var responses) || responses.ValueKind != JsonValueKind.Array)
            {
                throw new ArgumentException(Strings.BatchResponsesMissing, nameof(json));
            }

            var result = new List<BatchSubResponse>(responses.GetArrayLength());
            foreach (var response in responses.EnumerateArray())
            {
                var entry = new BatchSubResponse();
                if (TryGetProperty(response, "id", out var id))
                {
                    entry.Id = id.ValueKind == JsonValueKind.String ? id.GetString() : id.GetRawText();
                }

                // A status of another type than a whole number (a string, 1.5) stays 0 - TryGetInt32 throws on a
                // string - so one odd sub-response does not fail the whole envelope.
                if (TryGetProperty(response, "status", out var status) && status.ValueKind == JsonValueKind.Number && status.TryGetInt32(out var statusCode))
                {
                    entry.Status = statusCode;
                }

                if (TryGetProperty(response, "headers", out var headers) && headers.ValueKind == JsonValueKind.Object)
                {
                    entry.Headers = headers.GetRawText();
                    if (TryGetProperty(headers, "Retry-After", out var retryAfter))
                    {
                        var text = retryAfter.ValueKind == JsonValueKind.String ? retryAfter.GetString() : retryAfter.GetRawText();
                        entry.RetryAfter = RetryAfter.ParseSeconds(text);
                    }
                }

                if (TryGetProperty(response, "body", out var body) && body.ValueKind != JsonValueKind.Null)
                {
                    entry.Body = body.GetRawText();
                    if (body.ValueKind == JsonValueKind.Object)
                    {
                        // A link or message of another type than string is ignored, not a parser failure: GetString()
                        // throws on anything but a string or null.
                        if (TryGetProperty(body, "@odata.nextLink", out var next) && next.ValueKind == JsonValueKind.String)
                        {
                            entry.NextLink = next.GetString();
                        }

                        if (TryGetProperty(body, "@odata.deltaLink", out var delta) && delta.ValueKind == JsonValueKind.String)
                        {
                            entry.DeltaLink = delta.GetString();
                        }

                        if (TryGetProperty(body, "value", out var value) && value.ValueKind == JsonValueKind.Array)
                        {
                            entry.ItemCount = value.GetArrayLength();
                        }

                        if (TryGetProperty(body, "error", out var error) && error.ValueKind == JsonValueKind.Object && TryGetProperty(error, "message", out var message) && message.ValueKind == JsonValueKind.String)
                        {
                            entry.ErrorMessage = message.GetString();
                        }
                    }
                }

                result.Add(entry);
            }

            return result.ToArray();
        }

        private static bool TryGetProperty(JsonElement element, string name, out JsonElement value)
        {
            if (element.ValueKind == JsonValueKind.Object)
            {
                foreach (var property in element.EnumerateObject())
                {
                    if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
                    {
                        value = property.Value;
                        return true;
                    }
                }
            }

            value = default;
            return false;
        }
    }
}
