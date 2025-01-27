using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents a verified domain in Microsoft Entra ID.
    /// This class provides properties for domain capabilities, default status, initial status, name, and type.
    /// </summary>
    [DataContract]
    public class VerifiedDomain
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="VerifiedDomain"/> class.
        /// </summary>
        public VerifiedDomain()
        {
        }

        /// <summary>
        /// Gets or sets the capabilities of the verified domain.
        /// </summary>
        [DataMember(Name = "capabilities")]
        public string Capabilities { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the domain is the default domain.
        /// </summary>
        [DataMember(Name = "isDefault")]
        public bool? IsDefault { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the domain is the initial domain.
        /// </summary>
        [DataMember(Name = "isInitial")]
        public bool? IsInitial { get; set; }

        /// <summary>
        /// Gets or sets the name of the verified domain.
        /// </summary>
        [DataMember(Name = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the type of the verified domain.
        /// </summary>
        [DataMember(Name = "type")]
        public string Type { get; set; }
    }
}
