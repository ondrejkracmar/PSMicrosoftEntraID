using System;
using System.Collections.Generic;
using System.Management.Automation;
using PSMicrosoftEntraID.Batch;

namespace PSMicrosoftEntraID.Commands
{
    /// <summary>
    /// Cmdlet that receives Request objects from the pipeline and produces multiple 
    /// <see cref="BatchRequestPayload"/> objects, each containing up to 20 sub-requests. 
    /// In each chunk, request Ids are reassigned to "1", "2", etc. to comply with the 
    /// Microsoft Graph batch limit of 1..20 sub-requests per batch.
    /// </summary>
    [Cmdlet(VerbsCommon.New, "PSEntraIDBatchRequest", SupportsShouldProcess = true)]
    [OutputType(typeof(BatchRequestPayload))]
    public class NewPSEntraIDBatchRequest : PSCmdlet
    {
        private const int MaxBatchSize = 20;

        /// <summary>
        /// An array of Request objects coming from the pipeline. 
        /// Each item is a sub-request definition (method, url, body, etc.).
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true
        )]
        public Request[] InputObject { get; set; }

        /// <summary>
        /// Internal buffer to accumulate up to 20 requests before emitting a batch payload.
        /// </summary>
        private List<Request> _buffer = new List<Request>(MaxBatchSize);

        /// <summary>
        /// Called once before pipeline input is processed.
        /// </summary>
        protected override void BeginProcessing()
        {
            base.BeginProcessing();
        }

        /// <summary>
        /// Called once for each pipeline block of Request objects.
        /// We accumulate them, and each time we hit 20, we emit a new BatchRequestPayload 
        /// with Ids reindexed from "1" up to "n".
        /// </summary>
        protected override void ProcessRecord()
        {
            if (InputObject == null || InputObject.Length == 0)
                return;

            foreach (var req in InputObject)
            {
                _buffer.Add(req);

                // If we have 20 requests, emit them immediately
                if (_buffer.Count == MaxBatchSize)
                {
                    EmitOnePayload(_buffer);
                    _buffer.Clear();
                }
            }
        }

        /// <summary>
        /// Called after all pipeline input has been processed. 
        /// If there's any leftover (20) requests in _buffer, we emit one final payload.
        /// </summary>
        protected override void EndProcessing()
        {
            if (_buffer.Count > 0)
            {
                EmitOnePayload(_buffer);
                _buffer.Clear();
            }
        }

        /// <summary>
        /// Helper method to create a single BatchRequestPayload from up to 20 Request objects, 
        /// reindexing their Ids from "1" to the number of requests in this chunk.
        /// </summary>
        /// <param name="requests">A list of up to 20 Request objects.</param>
        private void EmitOnePayload(List<Request> requests)
        {
            // Reindex them "1".."n"
            int index = 1;
            foreach (var r in requests)
            {
                r.Id = index.ToString();
                index++;
            }

            // Build the payload
            var payload = new BatchRequestPayload();
            payload.Requests.AddRange(requests);

            // Output a single BatchRequestPayload object
            WriteObject(payload);
        }
    }
}
