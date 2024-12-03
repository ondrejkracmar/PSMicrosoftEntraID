using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSMicrosoftEntraID
    {
    /// <summary>
    /// What environment this service should connect to.
    /// </summary>
    public enum Environment
    {
        /// <summary>
        /// Global Microsoft cloud https://login.microsoftonline.com
        /// </summary>
        Global = 1,

        /// <summary>
        /// US Gov Microsoft cloud https://login.microsoftonline.us
        /// </summary>
        USGov = 2,

        /// <summary>
        /// US Gov DOD Microsoft cloud https://login.microsoftonline.us
        /// </summary>
        USGovDOD = 3,

        /// <summary>
        /// China Microsoft cloud https://login.chinacloudapi.cn
        /// </summary>
        China = 4,
    }
}
