using System.Collections.Generic;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Represents the final JSON payload for a Microsoft Graph batch request.
    /// Has a property named "requests" which is a list of Request objects.
    /// </summary>
    [DataContract]
    public class BatchRequestPayload
    {
        /// <summary>
        /// The "requests" array that Graph expects, each element having an Id, Method, Url, etc.
        /// </summary>
        [DataMember(Name = "requests")]
        public List<Request> Requests { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="BatchRequestPayload"/> class.
        /// </summary>
        public BatchRequestPayload()
        {
            Requests = new List<Request>();
        }
    }
}
