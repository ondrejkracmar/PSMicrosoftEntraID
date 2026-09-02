using System;
using System.Runtime.Serialization;

namespace PSMicrosoftEntraID.Devices
{
    /// <summary>
    /// The fifteen custom extension attributes of a directory device
    /// (Graph type onPremisesExtensionAttributes, property extensionAttributes).
    /// </summary>
    /// <remarks>
    /// Modeled as a fixed shape rather than a dictionary on purpose - every
    /// ConvertFrom-Rest* converter in this module round-trips through
    /// DataContractJsonSerializer, which does not handle open types. Dynamic
    /// device groups can rule on these values (device.extensionAttribute1-15),
    /// which is what makes them the landing spot for Defender for Endpoint
    /// machine tags.
    /// </remarks>
    [DataContract]
    public class ExtensionAttributes
    {
        /// <summary>First custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute1")]
        public string ExtensionAttribute1 { get; set; }

        /// <summary>Second custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute2")]
        public string ExtensionAttribute2 { get; set; }

        /// <summary>Third custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute3")]
        public string ExtensionAttribute3 { get; set; }

        /// <summary>Fourth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute4")]
        public string ExtensionAttribute4 { get; set; }

        /// <summary>Fifth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute5")]
        public string ExtensionAttribute5 { get; set; }

        /// <summary>Sixth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute6")]
        public string ExtensionAttribute6 { get; set; }

        /// <summary>Seventh custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute7")]
        public string ExtensionAttribute7 { get; set; }

        /// <summary>Eighth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute8")]
        public string ExtensionAttribute8 { get; set; }

        /// <summary>Ninth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute9")]
        public string ExtensionAttribute9 { get; set; }

        /// <summary>Tenth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute10")]
        public string ExtensionAttribute10 { get; set; }

        /// <summary>Eleventh custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute11")]
        public string ExtensionAttribute11 { get; set; }

        /// <summary>Twelfth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute12")]
        public string ExtensionAttribute12 { get; set; }

        /// <summary>Thirteenth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute13")]
        public string ExtensionAttribute13 { get; set; }

        /// <summary>Fourteenth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute14")]
        public string ExtensionAttribute14 { get; set; }

        /// <summary>Fifteenth custom extension attribute.</summary>
        [DataMember(Name = "extensionAttribute15")]
        public string ExtensionAttribute15 { get; set; }

        /// <summary>
        /// Returns the populated attributes as "extensionAttributeN=value" pairs,
        /// or an empty string when none are set.
        /// </summary>
        public override string ToString()
        {
            var parts = new System.Collections.Generic.List<string>();
            string[] values = {
                ExtensionAttribute1, ExtensionAttribute2, ExtensionAttribute3, ExtensionAttribute4,
                ExtensionAttribute5, ExtensionAttribute6, ExtensionAttribute7, ExtensionAttribute8,
                ExtensionAttribute9, ExtensionAttribute10, ExtensionAttribute11, ExtensionAttribute12,
                ExtensionAttribute13, ExtensionAttribute14, ExtensionAttribute15
            };
            for (int index = 0; index < values.Length; index++)
            {
                if (!string.IsNullOrEmpty(values[index]))
                {
                    parts.Add(string.Format("extensionAttribute{0}={1}", index + 1, values[index]));
                }
            }
            return string.Join("; ", parts);
        }
    }
}
