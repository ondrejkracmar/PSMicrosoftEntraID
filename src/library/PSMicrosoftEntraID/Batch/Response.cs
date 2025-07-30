using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Runtime.Serialization;
using PSMicrosoftEntraID.ServiceAnnouncement;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Represents a single response from Microsoft Graph API in a batch scenario.
    /// Not all properties are guaranteed to be present; headers and body may be null if not returned by the API.
    /// </summary>
    [DataContract]
    public class Response
    {
        /// <summary>
        /// Gets or sets the unique integer identifier of this response (matches request Id).
        /// Always present.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the HTTP status code returned by the API (e.g. 200, 404, 500).
        /// Always present.
        /// </summary>
        [DataMember(Name = "status")]
        public long Status { get; set; }

        /// <summary>
        /// Gets or sets the HTTP headers of the response as a hashtable (key-value pairs).
        /// May be null if not present in the response.
        /// </summary>
        [DataMember(Name = "headers")]
        public PSObject Headers { get; set; }

        /// <summary>
        /// Gets or sets the body of the response as a hashtable (typically parsed JSON).
        /// May be null if the response has no body or an error occurred.
        /// </summary>
        [DataMember(Name = "body")]
        public PSObject Body { get; set; }

        /// <summary>
        /// Returns a string representation for debugging purposes.
        /// Indicates whether body and headers are present.
        /// </summary>
        /// <returns>A string describing the response Id, Status, and presence of headers/body.</returns>
        public override string ToString()
        {
            return $"Response [Id={Id}, Status={Status}]";
        }
    }
}
