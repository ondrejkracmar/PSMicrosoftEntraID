# Microsoft Defender for Endpoint API

> [Back to Overview](overview.md)

This module ships two registered services for the Defender APIs next to the Graph services.
This page documents **which API to use for what**, the permissions each side needs, and how the
Defender for Endpoint (MDE) machine data relates to the Entra ID device objects - the basis for
synchronizing `machineTags` into device `extensionAttributes` (and back).

## Which API to use

| Service name | Service URL | Token resource (audience) | Use for |
|---|---|---|---|
| `PSMicrosoftEntraID.Endpoint` | `https://api.securitycenter.microsoft.com/api` | `https://api.securitycenter.microsoft.com` | MDE REST API: machines, machine tags, alerts, machine actions |
| `PSMicrosoftEntraID.Security` | `https://api.security.microsoft.com/api` | `https://security.microsoft.com/mtp/` | Microsoft Defender XDR: Advanced Hunting (`AdvancedHunting.Read`) |
| `PSMicrosoftEntraID.Graph` | `https://graph.microsoft.com/v1.0` | `https://graph.microsoft.com` | Entra ID device objects, `extensionAttributes`, dynamic groups |

> **Why the legacy audience?** Microsoft's current guidance is to keep requesting tokens for the
> legacy resource `https://api.securitycenter.microsoft.com` even when calling the newer
> `https://api.security.microsoft.com/api/...` URLs. Some MDE APIs still reject tokens issued for
> the new audience with `403 Forbidden`. The `PSMicrosoftEntraID.Endpoint` service is registered
> accordingly - do not "modernize" its resource.
> See [Create an app to access Microsoft Defender for Endpoint without a user](https://learn.microsoft.com/en-us/defender-endpoint/api/exposed-apis-create-app-webapp).

The Intune endpoint `deviceManagement/managedDevices` is **not** the right target for tag/attribute
synchronization: a device onboarded to MDE without Intune enrollment (`managementAgent: msSense`)
returns a mostly empty managed-device record. The directory object `GET /devices` is the one that
carries `extensionAttributes` and feeds dynamic device groups.

## Required permissions

### WindowsDefenderATP (MDE side)

Add these from **APIs my organization uses → WindowsDefenderATP** in the app registration:

| Operation | Application | Delegated |
|---|---|---|
| Read machines (`GET /machines`, `GET /machines/{id}`) | `Machine.Read.All` | `Machine.Read` |
| Add/remove machine tags (`POST /machines/{id}/tags`) | `Machine.ReadWrite.All` | `Machine.ReadWrite` |

Delegated calls additionally require the MDE role permission **'Manage security setting'** and
access to the machine's device group. Tag writes are rate limited to **100 calls/minute and
1,500 calls/hour**.

### Microsoft Graph (Entra ID side)

| Operation | Application | Delegated |
|---|---|---|
| Read devices (`GET /devices`) | `Device.Read.All` | `Device.Read.All` |
| Write `extensionAttributes` (`PATCH /devices/{id}`) | `Device.ReadWrite.All` | `Directory.AccessAsUser.All` + Intune Administrator role |

App-only callers may update **only** the `extensionAttributes` property of a device - which is
exactly what a tag synchronization needs, so `Device.ReadWrite.All` is sufficient and least
privileged. See [Update device](https://learn.microsoft.com/en-us/graph/api/device-update?view=graph-rest-1.0).

A single app registration can hold the WindowsDefenderATP and the Graph permissions side by side;
the client-credentials flow requests one token per resource.

## Connecting

Connect to both services in a single call - each service family keeps its own default-service
setting, so connecting to Defender for Endpoint never redirects the regular Graph cmdlets:

```powershell
Connect-PSMicrosoftEntraID -Service 'PSMicrosoftEntraID.Graph', 'PSMicrosoftEntraID.Endpoint' `
    -ClientID $clientId -TenantID $tenantId -CertificateThumbprint $thumbprint
```

| Setting | Default | Read by |
|---|---|---|
| `PSMicrosoftEntraID.Settings.DefaultService` | `PSMicrosoftEntraID.Graph` | all Graph cmdlets |
| `PSMicrosoftEntraID.Settings.DefaultServiceEndpoint` | `PSMicrosoftEntraID.Endpoint` | Defender for Endpoint requests |
| `PSMicrosoftEntraID.Settings.DefaultServiceSecurity` | `PSMicrosoftEntraID.Security` | Defender XDR requests |

The subscribed-license cache is only populated when a Graph-family service is among the connected
services; an Endpoint-only connect skips it.

## Calling the MDE API

The typed cmdlets cover the machine surface - `*-PSEntraIDDevice` reads the
directory device, `*-PSEntraIDMachine` reads Defender for Endpoint:

```powershell
# All machines, one by its MDE machine id, or by a filter
Get-PSEntraIDMachine
Get-PSEntraIDMachine -Identity '1e5bc9d7e413ddd7902c2932e418702b84d0cc07'
Get-PSEntraIDMachine -Filter "healthStatus eq 'Active'"

# The MDE machine record(s) of a known Entra ID device (join key)
Get-PSEntraIDMachine -DeviceId $device.DeviceId

# Machine tags (Machine.ReadWrite.All; 100 calls/min, 1500 calls/h)
Get-PSEntraIDMachine -DeviceId $device.DeviceId | Add-PSEntraIDMachineTag -Tag 'test tag 1'
Remove-PSEntraIDMachineTag -MachineId $machine.Id -Tag 'test tag 1'
```

Anything the cmdlets do not cover yet is still reachable raw:

```powershell
Invoke-PSEntraIDRequest -Service PSMicrosoftEntraID.Endpoint -Path 'alerts' -Method Get
```

The `/machines` list supports `$filter` on `computerDnsName`, `id`, `version`, `deviceValue`,
`aadDeviceId`, `machineTags`, `lastSeen`, `exposureLevel`, `onboardingStatus`, `lastIpAddress`,
`healthStatus`, `osPlatform`, `riskScore` and `rbacGroupId`
([List machines](https://learn.microsoft.com/en-us/defender-endpoint/api/get-machines)).

## How MDE machines map to Entra ID devices

| MDE machine property | Entra ID device property | Note |
|---|---|---|
| `id` | - | MDE machine id (hash), exists only in MDE |
| `aadDeviceId` | `deviceId` | **the join key**; empty for machines that are not Entra joined/registered |
| `computerDnsName` | `displayName` | display match only, not reliable as a key |
| `machineTags` | `extensionAttributes.extensionAttribute1..15` | the synchronization payload |

The Graph device can be addressed by the join key directly, no directory-object-id lookup needed:

```powershell
# Write an MDE machine tag into extensionAttribute1 of the matching Entra ID device
Set-PSEntraIDDeviceExtensionAttribute -DeviceId $machine.AadDeviceId `
    -AttributeName extensionAttribute1 -Value $machine.MachineTags[0]

# Clear it again (clears with null - a dynamic group rule never matches '')
Set-PSEntraIDDeviceExtensionAttribute -DeviceId $machine.AadDeviceId `
    -AttributeName extensionAttribute1 -Value ''
```

Dynamic device groups can then rule on the attribute, e.g.
`(device.extensionAttribute1 -eq "test tag 1")` - Intune is not required anywhere in this chain.

> The Intune record shows the same key as `azureADDeviceId`; MDE calls it `aadDeviceId`; the
> directory device calls it `deviceId`. All three are the same GUID.

|[Back to Overview](overview.md)|
