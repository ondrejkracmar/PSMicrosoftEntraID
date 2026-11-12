using System;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// One answer of a Graph $batch envelope as read by <see cref="GraphBatchReader"/>: the status and the paging
    /// links already extracted, the body kept as raw JSON so it can be deserialized straight into typed objects
    /// without building PowerShell objects first.
    /// </summary>
    public class BatchSubResponse
    {
        /// <summary>Gets or sets the id of the sub-request answered.</summary>
        public string Id { get; set; }

        /// <summary>Gets or sets the HTTP status of the sub-request.</summary>
        public int Status { get; set; }

        /// <summary>
        /// Gets or sets the wait the Retry-After header asks for (seconds or an HTTP-date) in seconds, at most
        /// <see cref="Batch.RetryAfter.MaximumSeconds"/>; 0 when absent.
        /// </summary>
        public int RetryAfter { get; set; }

        /// <summary>Gets or sets the body as raw JSON, null when the sub-response has none.</summary>
        public string Body { get; set; }

        /// <summary>Gets or sets the headers object of the sub-response as raw JSON, null when it has none.</summary>
        public string Headers { get; set; }

        /// <summary>Gets or sets the @odata.nextLink of a collection page.</summary>
        public string NextLink { get; set; }

        /// <summary>Gets or sets the @odata.deltaLink of the last page of a delta read.</summary>
        public string DeltaLink { get; set; }

        /// <summary>Gets or sets the number of items in the "value" array of a collection page.</summary>
        public int ItemCount { get; set; }

        /// <summary>Gets or sets the Graph error message of a failed sub-request.</summary>
        public string ErrorMessage { get; set; }

        /// <summary>
        /// Gets or sets the items of the page as typed objects, when the envelope was sent with an element type
        /// (<see cref="GraphBatchClient"/>); null otherwise, or when the page could not be converted.
        /// </summary>
        public Array Items { get; set; }

        /// <summary>
        /// Gets or sets why the body of a successful page could not be converted to the element type; null when it was
        /// converted or no conversion was asked for. Names the exception type and the JSON path, never the body.
        /// </summary>
        public string ConversionError { get; set; }

        /// <summary>Gets whether the sub-request succeeded (status below 400).</summary>
        public bool IsSuccess => Status >= 200 && Status < 400;
    }
}
