using System;
using System.Collections;
using System.Collections.Generic;

namespace PSMicrosoftEntraID.Batch
{
    /// <summary>
    /// Represents a single request to Microsoft Entra ID (Azure AD).
    /// This class is compatible with both .NET 4.7 and .NET Standard 2.0.
    /// </summary>
    public class Request
    {
        /// <summary>
        /// A set of allowed HTTP methods for this request.
        /// </summary>
        private static readonly HashSet<string> AllowedMethods = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "Get",
            "Put",
            "Patch",
            "Post",
            "Delete"
        };

        /// <summary>
        /// Backing field for the <see cref="Method"/> property,
        /// storing the HTTP method used by this request.
        /// </summary>
        private string _method;

        /// <summary>
        /// Gets or sets the unique identifier of this request (e.g., "1", "2", "3"...).
        /// Typically used to distinguish multiple requests in a batch scenario.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// Gets or sets the HTTP method (e.g., GET, PUT, PATCH, POST, DELETE).
        /// The setter validates that the method is allowed. 
        /// If the provided value is not in the allowed set, an <see cref="ArgumentException"/> is thrown.
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
        /// Gets or sets the URL (endpoint) that this request will target.
        /// For example, "/me/drive/root:/content" or "/groups/{id}/events".
        /// </summary>
        public string Url { get; set; }

        /// <summary>
        /// Gets or sets the body of the request as a <see cref="Hashtable"/>.
        /// This approach allows for easy manipulation in PowerShell as a native [hashtable].
        /// Note that not all HTTP methods require a body.
        /// </summary>
        public Hashtable Body { get; set; } = new Hashtable();

        /// <summary>
        /// Gets or sets the headers of the request as a <see cref="Hashtable"/>.
        /// Each entry is a key-value pair representing a single HTTP header (e.g., "Content-Type").
        /// </summary>
        public Hashtable Headers { get; set; } = new Hashtable();

        /// <summary>
        /// Provides a simple string representation of this request,
        /// showing the Id, Method, and Url properties for quick reference.
        /// </summary>
        /// <returns>A string describing the current request.</returns>
        public override string ToString()
        {
            return $"Request [Id={Id}, Method={Method}, Url={Url}]";
        }
    }
}
