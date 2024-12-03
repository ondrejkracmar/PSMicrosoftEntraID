using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.Organization
{
    /// <summary>
    /// Represents the synchronization status for on-premises directory in Microsoft Entra ID.
    /// This class provides properties for the attribute set name, sync state, and version.
    /// </summary>
    [DataContract]
    public class OnPremisesSyncStatus
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="OnPremisesSyncStatus"/> class.
        /// </summary>
        public OnPremisesSyncStatus()
        {
        }

        /// <summary>
        /// Gets or sets the name of the attribute set used for synchronization.
        /// </summary>
        [DataMember(Name = "attributeSetName")]
        public string AttributeSetName { get; set; }

        /// <summary>
        /// Gets or sets the current state of the on-premises synchronization.
        /// </summary>
        [DataMember(Name = "state")]
        public string State { get; set; }

        /// <summary>
        /// Gets or sets the version of the on-premises synchronization configuration.
        /// </summary>
        [DataMember(Name = "version")]
        public string Version { get; set; }
    }
}
