using System;
using System.Collections;
using System.Collections.Generic;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Represents a single request to Microsoft Entra ID (Azure AD) in a batch scenario.
    /// Compatible with .NET 4.7 or .NET Standard 2.0.
    /// </summary>
    public class Request
    {
        /// <summary>
        /// A set of allowed HTTP methods for this request (GET, PUT, PATCH, POST, DELETE).
        /// </summary>
        private static readonly HashSet<string> AllowedMethods = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Get", "Put", "Patch", "Post", "Delete"
        };

        /// <summary>
        /// Backing field for the HTTP method.
        /// </summary>
        private string _method;

        /// <summary>
        /// Gets or sets the unique identifier of this request (e.g. "1", "2", "3").
        /// Typically used to distinguish multiple requests in a single batch.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the HTTP method (GET, PUT, PATCH, POST, DELETE).
        /// The setter validates that the method is allowed, otherwise throws an ArgumentException.
        /// </summary>
        public string Method
        {
            get => _method;
            set
            {
                if (!AllowedMethods.Contains(value))
                {
                    throw new ArgumentException(
                        $"Method must be one of: {string.Join(", ", AllowedMethods)}. Provided: {value}"
                    );
                }
                _method = value;
            }
        }

        /// <summary>
        /// Gets or sets the URL (endpoint) that this request will call (e.g. "/users", "/groups/{id}", etc.).
        /// </summary>
        public string Url { get; set; }

        /// <summary>
        /// Gets or sets the body of the request as a hashtable, useful for PowerShell scenarios.
        /// </summary>
        public Hashtable Body { get; set; } = new Hashtable();

        /// <summary>
        /// Gets or sets the headers of the request as a hashtable (key-value pairs).
        /// </summary>
        public Hashtable Headers { get; set; } = new Hashtable();

        /// <summary>
        /// Returns a string representation for debugging.
        /// </summary>
        /// <returns>String describing the request Id, Method, Url.</returns>
        public override string ToString()
        {
            return $"Request [Id={Id}, Method={Method}, Url={Url}]";
        }
    }
}
