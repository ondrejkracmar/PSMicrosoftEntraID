using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents the status of prepaid units in Microsoft Entra ID.
    /// This class provides properties for tracking enabled, suspended, warning, and locked-out units.
    /// </summary>
    [DataContract]
    public class PrepaidUnit
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="PrepaidUnit"/> class.
        /// </summary>
        public PrepaidUnit()
        {
        }

        /// <summary>
        /// Gets or sets the number of enabled units.
        /// </summary>
        [DataMember(Name = "enabled")]
        public int Enabled { get; set; }

        /// <summary>
        /// Gets or sets the number of suspended units.
        /// </summary>
        [DataMember(Name = "suspended")]
        public int Suspended { get; set; }

        /// <summary>
        /// Gets or sets the number of units in a warning state.
        /// </summary>
        [DataMember(Name = "warning")]
        public int Warning { get; set; }

        /// <summary>
        /// Gets or sets the number of locked-out units.
        /// </summary>
        [DataMember(Name = "lockedOut")]
        public int LockedOut { get; set; }
    }
}
