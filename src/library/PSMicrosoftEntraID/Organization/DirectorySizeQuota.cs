using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents the directory size quota for an organization in Microsoft Entra ID.
    /// This class provides properties for tracking the used and total directory storage.
    /// </summary>
    [DataContract]
    public class DirectorySizeQuota
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="DirectorySizeQuota"/> class.
        /// </summary>
        public DirectorySizeQuota()
        {
        }

        /// <summary>
        /// Gets or sets the amount of directory storage used.
        /// </summary>
        [DataMember(Name = "used")]
        public int Used { get; set; }

        /// <summary>
        /// Gets or sets the total directory storage quota.
        /// </summary>
        [DataMember(Name = "total")]
        public int Total { get; set; }
    }
}
