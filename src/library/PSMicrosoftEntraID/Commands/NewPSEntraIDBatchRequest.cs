using System.Linq;
using System.Management.Automation;
using System.Reflection;
using PSMicrosoftEntraID.Batch;

namespace PSMicrosoftEntraID.Commands
{
    /// <summary>
    /// Cmdlet that receives an array of Request objects, renumbers their 'Id' properties
    /// as sequential strings ("1", "2", "3", ...), and outputs the updated array.
    /// </summary>
    [Cmdlet(VerbsCommon.New, "PSEntraIDBatchRequest")]
    [OutputType(typeof(Request[]))]
    public class NewPSEntraIDBatchRequest : PSCmdlet
    {
        /// <summary>
        /// Input array of Request objects. Their Ids will be reassigned in EndProcessing.
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true
        )]
        public Request[] InputObject { get; set; }
        private int _index;

        /// <summary>
        /// Start collecting all input, renumber Ids from "1" to the total count, then write them out.
        /// </summary>
        protected override void BeginProcessing()
        {
            _index = 1;
        }
        /// <summary>
        /// Called once for each pipeline input chunk. 
        /// In this scenario, final logic will occur in EndProcessing.
        /// </summary>
        protected override void ProcessRecord()
        {
            foreach (var item in InputObject)
            {
                // Assign Id as a string reflecting the 1-based index.
                item.Id = _index.ToString();
                _index++;
                // Output the modified array as a single object
                WriteObject(item);
            }
        }

        /// <summary>
        /// After collecting all input, renumber Ids from "1" to the total count, then write them out.
        /// </summary>
        protected override void EndProcessing()
        {
            
        }
    }
}
