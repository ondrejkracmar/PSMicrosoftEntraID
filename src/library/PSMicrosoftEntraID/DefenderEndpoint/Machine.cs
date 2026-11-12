using System;

namespace PSMicrosoftEntraID.DefenderEndpoint
{
    /// <summary>
    /// Represents a machine (device) onboarded to Microsoft Defender for Endpoint,
    /// as returned by the MDE API (service PSMicrosoftEntraID.Endpoint,
    /// GET /machines and GET /machines/{id}).
    /// </summary>
    /// <remarks>
    /// The MDE machine id is a hash issued by Defender and exists only there. The
    /// bridge to the directory is <see cref="AadDeviceId"/>, which equals the
    /// deviceId of the Entra ID device object (PSMicrosoftEntraID.Devices.Device.DeviceId).
    /// Rarely used nested members (ipAddresses, vmMetadata) are omitted until needed -
    /// the deserializer (GraphJson) ignores unknown JSON members.
    /// </remarks>
    public class Machine
    {
        /// <summary>
        /// The machine identity issued by Defender for Endpoint.
        /// </summary>
        public string Id { get; set; }

        /// <summary>
        /// The fully qualified DNS name of the machine.
        /// </summary>
        public string ComputerDnsName { get; set; }

        /// <summary>
        /// When the machine was first seen by the Defender for Endpoint sensor.
        /// </summary>
        public DateTime? FirstSeen { get; set; }

        /// <summary>
        /// When the machine last reported to the Defender for Endpoint service.
        /// </summary>
        public DateTime? LastSeen { get; set; }

        /// <summary>
        /// The operating system platform, for example Windows11 or Linux.
        /// </summary>
        public string OsPlatform { get; set; }

        /// <summary>
        /// The operating system version.
        /// </summary>
        public string Version { get; set; }

        /// <summary>
        /// The operating system processor architecture, for example x64.
        /// </summary>
        public string OsProcessor { get; set; }

        /// <summary>
        /// The operating system build number.
        /// </summary>
        public long? OsBuild { get; set; }

        /// <summary>
        /// The last IP address reported on a local interface of the machine.
        /// </summary>
        public string LastIpAddress { get; set; }

        /// <summary>
        /// The last public IP address the machine accessed the service from.
        /// </summary>
        public string LastExternalIpAddress { get; set; }

        /// <summary>
        /// The Defender for Endpoint agent version.
        /// </summary>
        public string AgentVersion { get; set; }

        /// <summary>
        /// The sensor health state, for example Active or Inactive.
        /// </summary>
        public string HealthStatus { get; set; }

        /// <summary>
        /// The assigned device value (Normal, Low, High).
        /// </summary>
        public string DeviceValue { get; set; }

        /// <summary>
        /// The identifier of the RBAC device group the machine belongs to.
        /// </summary>
        public long? RbacGroupId { get; set; }

        /// <summary>
        /// The name of the RBAC device group the machine belongs to.
        /// </summary>
        public string RbacGroupName { get; set; }

        /// <summary>
        /// The risk score as evaluated by Defender for Endpoint
        /// (None, Informational, Low, Medium, High).
        /// </summary>
        public string RiskScore { get; set; }

        /// <summary>
        /// The exposure level of the machine (None, Low, Medium, High).
        /// </summary>
        public string ExposureLevel { get; set; }

        /// <summary>
        /// Whether the machine is joined to Microsoft Entra ID.
        /// </summary>
        public bool? IsAadJoined { get; set; }

        /// <summary>
        /// The Entra ID device identifier. Equals the deviceId of the directory
        /// device object - the join key between Defender for Endpoint and Entra ID.
        /// Empty for machines that are not Entra joined or registered.
        /// </summary>
        public string AadDeviceId { get; set; }

        /// <summary>
        /// The onboarding state of the machine, for example Onboarded.
        /// </summary>
        public string OnboardingStatus { get; set; }

        /// <summary>
        /// The Microsoft Defender Antivirus status, for example Updated or Disabled.
        /// </summary>
        public string DefenderAvStatus { get; set; }

        /// <summary>
        /// The operating system architecture reported by the sensor.
        /// </summary>
        public string OsArchitecture { get; set; }

        /// <summary>
        /// Which authority manages the machine, for example Intune or MDE.
        /// </summary>
        public string ManagedBy { get; set; }

        /// <summary>
        /// The management enrollment status of the managing authority.
        /// </summary>
        public string ManagedByStatus { get; set; }

        /// <summary>
        /// The identifier of the machine this record was merged into, when the
        /// record was detected as a duplicate.
        /// </summary>
        public string MergedIntoMachineId { get; set; }

        /// <summary>
        /// Whether the record was detected as a potential duplicate of another one.
        /// </summary>
        public bool? IsPotentialDuplication { get; set; }

        /// <summary>
        /// Whether the machine is excluded from views and reports.
        /// </summary>
        public bool? IsExcluded { get; set; }

        /// <summary>
        /// The reason the machine was excluded, when it is.
        /// </summary>
        public string ExclusionReason { get; set; }

        /// <summary>
        /// The machine tags attached in Defender for Endpoint - the payload of the
        /// tag to extensionAttribute synchronization.
        /// </summary>
        public string[] MachineTags { get; set; }

        /// <summary>
        /// Returns the DNS name, falling back to the identifier.
        /// </summary>
        public override string ToString()
        {
            return string.IsNullOrWhiteSpace(ComputerDnsName) ? Id : ComputerDnsName;
        }
    }
}
