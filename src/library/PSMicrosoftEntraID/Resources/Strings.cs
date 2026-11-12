using System.Globalization;
using System.Resources;

namespace PSMicrosoftEntraID.Resources
{
    /// <summary>
    /// The messages of the library, read from Strings.resx (embedded as PSMicrosoftEntraID.Resources.Strings).
    /// Written by hand instead of generated: the project carries no designer generator metadata.
    /// </summary>
    internal static class Strings
    {
        private static readonly ResourceManager Manager = new ResourceManager("PSMicrosoftEntraID.Resources.Strings", typeof(Strings).Assembly);

        /// <summary>Gets or sets the culture the messages are read in; null for the current UI culture.</summary>
        internal static CultureInfo Culture { get; set; }

        /// <summary>The JSON text is empty.</summary>
        internal static string JsonEmpty => Get(nameof(JsonEmpty));

        /// <summary>The answer has no "responses" array.</summary>
        internal static string BatchResponsesMissing => Get(nameof(BatchResponsesMissing));

        /// <summary>No service URL to authorize the envelope against.</summary>
        internal static string BatchNoServiceUrl => Get(nameof(BatchNoServiceUrl));

        /// <summary>The envelope URL is not absolute or carries user information.</summary>
        internal static string BatchInvalidUrl => Get(nameof(BatchInvalidUrl));

        /// <summary>{0} is not an https URL.</summary>
        internal static string BatchNotHttps => Get(nameof(BatchNotHttps));

        /// <summary>{0} is not on the host of the service ({1}).</summary>
        internal static string BatchForeignHost => Get(nameof(BatchForeignHost));

        /// <summary>The request was cancelled.</summary>
        internal static string BatchCancelled => Get(nameof(BatchCancelled));

        /// <summary>The answer is not a valid $batch response ({0}).</summary>
        internal static string BatchInvalidAnswer => Get(nameof(BatchInvalidAnswer));

        /// <summary>The answer is not a valid $batch response ({0} at line {1}, byte {2}).</summary>
        internal static string BatchInvalidAnswerAt => Get(nameof(BatchInvalidAnswerAt));

        /// <summary>The page could not be converted to {0} ({1} at {2}).</summary>
        internal static string ConversionFailed => Get(nameof(ConversionFailed));

        private static string Get(string name) => Manager.GetString(name, Culture) ?? name;
    }
}
