using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Represents the entire payload returned by a Microsoft Graph batch operation.
    /// Contains both the original requests and the corresponding responses as returned by the API.
    /// </summary>
    public class BatchResponsePayload
    {
        /// <summary>
        /// Gets or sets the list of requests sent in the batch operation.
        /// This property typically mirrors the original batch input for traceability.
        /// </summary>
        public List<Request> Requests { get; set; }

        /// <summary>
        /// Gets or sets the list of responses returned from Microsoft Graph for each request in the batch.
        /// The order and number of responses may not always match the requests, so matching by Id is recommended.
        /// </summary>
        public List<Response> Responses { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="BatchResponsePayload"/> class.
        /// </summary>
        public BatchResponsePayload()
        {
            Requests = new List<Request>();
            Responses = new List<Response>();
        }
    }
}