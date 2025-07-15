using System.Management.Automation;

namespace PSMicrosoftEntraID
{
    /// <summary>
    /// Represents a federation provider with scriptblock logic for use in PowerShell automation.
    /// </summary>
    public class FederationProvider
    {
        /// <summary>
        /// Gets or sets the name of the federation provider.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the description of the federation provider.
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets the priority of the federation provider.
        /// </summary>
        public int Priority { get; set; }

        /// <summary>
        /// Gets or sets the test scriptblock.
        /// </summary>
        public ScriptBlock Test { get; set; }

        /// <summary>
        /// Gets or sets the main code scriptblock.
        /// </summary>
        public ScriptBlock Code { get; set; }

        /// <summary>
        /// Gets or sets the assertion string.
        /// </summary>
        public string Assertion { get; set; }

        private string _type = "Custom";

        /// <summary>
        /// Gets or sets the type of the federation provider. Default is "Custom".
        /// </summary>
        public string Type
        {
            get => _type;
            set => _type = value ?? "Custom";
        }

        /// <summary>
        /// Returns the name of the federation provider.
        /// </summary>
        /// <returns>The name of the provider.</returns>
        public override string ToString()
        {
            return Name;
        }
    }
}
