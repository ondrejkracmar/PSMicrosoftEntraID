using System;
using System.Runtime.Serialization;

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
    /// DataContractJsonSerializer ignores unknown JSON members.
    /// </remarks>
    [DataContract]
    public class Machine
    {
        /// <summary>
        /// The machine identity issued by Defender for Endpoint.
        /// </summary>
        [DataMember(Name = "id")]
        public string Id { get; set; }

        /// <summary>
        /// The fully qualified DNS name of the machine.
        /// </summary>
        [DataMember(Name = "computerDnsName")]
        public string ComputerDnsName { get; set; }

        /// <summary>
        /// When the machine was first seen by the Defender for Endpoint sensor.
        /// </summary>
        [DataMember(Name = "firstSeen")]
        public string FirstSeen { get; set; }

        /// <summary>
        /// When the machine last reported to the Defender for Endpoint service.
        /// </summary>
        [DataMember(Name = "lastSeen")]
        public string LastSeen { get; set; }

        /// <summary>
        /// The operating system platform, for example Windows11 or Linux.
        /// </summary>
        [DataMember(Name = "osPlatform")]
        public string OsPlatform { get; set; }

        /// <summary>
        /// The operating system version.
        /// </summary>
        [DataMember(Name = "version")]
        public string Version { get; set; }

        /// <summary>
        /// The operating system processor architecture, for example x64.
        /// </summary>
        [DataMember(Name = "osProcessor")]
        public string OsProcessor { get; set; }

        /// <summary>
        /// The operating system build number.
        /// </summary>
        [DataMember(Name = "osBuild")]
        public long? OsBuild { get; set; }

        /// <summary>
        /// The last IP address reported on a local interface of the machine.
        /// </summary>
        [DataMember(Name = "lastIpAddress")]
        public string LastIpAddress { get; set; }

        /// <summary>
        /// The last public IP address the machine accessed the service from.
        /// </summary>
        [DataMember(Name = "lastExternalIpAddress")]
        public string LastExternalIpAddress { get; set; }

        /// <summary>
        /// The Defender for Endpoint agent version.
        /// </summary>
        [DataMember(Name = "agentVersion")]
        public string AgentVersion { get; set; }

        /// <summary>
        /// The sensor health state, for example Active or Inactive.
        /// </summary>
        [DataMember(Name = "healthStatus")]
        public string HealthStatus { get; set; }

        /// <summary>
        /// The assigned device value (Normal, Low, High).
        /// </summary>
        [DataMember(Name = "deviceValue")]
        public string DeviceValue { get; set; }

        /// <summary>
        /// The identifier of the RBAC device group the machine belongs to.
        /// </summary>
        [DataMember(Name = "rbacGroupId")]
        public long? RbacGroupId { get; set; }

        /// <summary>
        /// The name of the RBAC device group the machine belongs to.
        /// </summary>
        [DataMember(Name = "rbacGroupName")]
        public string RbacGroupName { get; set; }

        /// <summary>
        /// The risk score as evaluated by Defender for Endpoint
        /// (None, Informational, Low, Medium, High).
        /// </summary>
        [DataMember(Name = "riskScore")]
        public string RiskScore { get; set; }

        /// <summary>
        /// The exposure level of the machine (None, Low, Medium, High).
        /// </summary>
        [DataMember(Name = "exposureLevel")]
        public string ExposureLevel { get; set; }

        /// <summary>
        /// Whether the machine is joined to Microsoft Entra ID.
        /// </summary>
        [DataMember(Name = "isAadJoined")]
        public bool? IsAadJoined { get; set; }

        /// <summary>
        /// The Entra ID device identifier. Equals the deviceId of the directory
        /// device object - the join key between Defender for Endpoint and Entra ID.
        /// Empty for machines that are not Entra joined or registered.
        /// </summary>
        [DataMember(Name = "aadDeviceId")]
        public string AadDeviceId { get; set; }

        /// <summary>
        /// The onboarding state of the machine, for example Onboarded.
        /// </summary>
        [DataMember(Name = "onboardingStatus")]
        public string OnboardingStatus { get; set; }

        /// <summary>
        /// The Microsoft Defender Antivirus status, for example Updated or Disabled.
        /// </summary>
        [DataMember(Name = "defenderAvStatus")]
        public string DefenderAvStatus { get; set; }

        /// <summary>
        /// The operating system architecture reported by the sensor.
        /// </summary>
        [DataMember(Name = "osArchitecture")]
        public string OsArchitecture { get; set; }

        /// <summary>
        /// Which authority manages the machine, for example Intune or MDE.
        /// </summary>
        [DataMember(Name = "managedBy")]
        public string ManagedBy { get; set; }

        /// <summary>
        /// The management enrollment status of the managing authority.
        /// </summary>
        [DataMember(Name = "managedByStatus")]
        public string ManagedByStatus { get; set; }

        /// <summary>
        /// The identifier of the machine this record was merged into, when the
        /// record was detected as a duplicate.
        /// </summary>
        [DataMember(Name = "mergedIntoMachineId")]
        public string MergedIntoMachineId { get; set; }

        /// <summary>
        /// Whether the record was detected as a potential duplicate of another one.
        /// </summary>
        [DataMember(Name = "isPotentialDuplication")]
        public bool? IsPotentialDuplication { get; set; }

        /// <summary>
        /// Whether the machine is excluded from views and reports.
        /// </summary>
        [DataMember(Name = "isExcluded")]
        public bool? IsExcluded { get; set; }

        /// <summary>
        /// The reason the machine was excluded, when it is.
        /// </summary>
        [DataMember(Name = "exclusionReason")]
        public string ExclusionReason { get; set; }

        /// <summary>
        /// The machine tags attached in Defender for Endpoint - the payload of the
        /// tag to extensionAttribute synchronization.
        /// </summary>
        [DataMember(Name = "machineTags")]
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
