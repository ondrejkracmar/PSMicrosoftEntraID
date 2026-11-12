using System;

namespace PSMicrosoftEntraID.Devices
{
    /// <summary>
    /// Represents a device registered in Microsoft Entra ID.
    /// </summary>
    /// <remarks>
    /// Get-PSEntraIDDevice declared [OutputType('PSMicrosoftEntraID.Devices.Device')]
    /// while no such type existed - the cmdlet returned raw Graph objects and the
    /// declaration pointed at nothing. This is that type.
    /// </remarks>
    public class Device
    {
        /// <summary>
        /// The unique identifier of the device object in the directory.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// The device identifier assigned by the operating system.
        /// </summary>
        public string DeviceId { get; set; }

        /// <summary>
        /// The display name of the device.
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// Whether the device is enabled. A disabled device cannot authenticate.
        /// </summary>
        public bool? AccountEnabled { get; set; }

        /// <summary>
        /// The operating system running on the device.
        /// </summary>
        public string OperatingSystem { get; set; }

        /// <summary>
        /// The version of the operating system.
        /// </summary>
        public string OperatingSystemVersion { get; set; }

        /// <summary>
        /// How the device is joined to the directory, for example AzureAd or
        /// ServerAd.
        /// </summary>
        public string TrustType { get; set; }

        /// <summary>
        /// Whether the device is managed by an MDM such as Intune.
        /// </summary>
        public bool? IsManaged { get; set; }

        /// <summary>
        /// Whether the device is marked as compliant with policy.
        /// </summary>
        public bool? IsCompliant { get; set; }

        /// <summary>
        /// The manufacturer of the device.
        /// </summary>
        public string Manufacturer { get; set; }

        /// <summary>
        /// The model of the device.
        /// </summary>
        public string Model { get; set; }

        /// <summary>
        /// When the device was registered in the directory.
        /// </summary>
        public DateTime? RegistrationDateTime { get; set; }

        /// <summary>
        /// When the device last signed in, as reported by the directory.
        /// </summary>
        public DateTime? ApproximateLastSignInDateTime { get; set; }

        /// <summary>
        /// The fifteen custom extension attributes of the device. The only device
        /// property an app-only caller may update, and the target for dynamic
        /// device group membership rules.
        /// </summary>
        public ExtensionAttributes ExtensionAttributes { get; set; }

        /// <summary>
        /// Returns the display name, falling back to the identifier.
        /// </summary>
        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(DisplayName) ? Id : DisplayName;
        }
    }
}
