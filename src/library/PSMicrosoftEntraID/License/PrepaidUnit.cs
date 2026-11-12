using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID.License
{
    /// <summary>
    /// Represents the status of prepaid units in Microsoft Entra ID.
    /// This class provides properties for tracking enabled, suspended, warning, and locked-out units.
    /// </summary>
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
        public int? Enabled { get; set; }

        /// <summary>
        /// Gets or sets the number of suspended units.
        /// </summary>
        public int? Suspended { get; set; }

        /// <summary>
        /// Gets or sets the number of units in a warning state.
        /// </summary>
        public int? Warning { get; set; }

        /// <summary>
        /// Gets or sets the number of locked-out units.
        /// </summary>
        public int? LockedOut { get; set; }
    }
}
