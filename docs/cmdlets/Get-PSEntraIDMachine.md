---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 09/02/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDMachine
---

# Get-PSEntraIDMachine

## SYNOPSIS

Get machines onboarded to Microsoft Defender for Endpoint.

## SYNTAX

### List (Default)

```
Get-PSEntraIDMachine [-EnableException]
```

### Identity

```
Get-PSEntraIDMachine -Identity <string[]> [-EnableException]
```

### DeviceId

```
Get-PSEntraIDMachine -DeviceId <guid[]> [-EnableException]
```

### Filter

```
Get-PSEntraIDMachine -Filter <string> [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Reads the Defender for Endpoint machines API (service family Endpoint,
Settings.DefaultServiceEndpoint - connect with
Connect-PSMicrosoftEntraID -Service PSMicrosoftEntraID.Endpoint).

Without parameters, every machine is returned.
The MDE machine id is a
hash issued by Defender and exists only there; the bridge to the
directory is AadDeviceId, which equals the DeviceId of the Entra ID
device object returned by Get-PSEntraIDDevice.
Note that AadDeviceId is
NOT unique among machine records - a re-onboarded device leaves its old
record behind - so -DeviceId may return several records; inspect
MergedIntoMachineId, IsExcluded, OnboardingStatus and LastSeen to pick
the live one.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDMachine

Every machine onboarded to Defender for Endpoint.

### EXAMPLE 2

Get-PSEntraIDDevice -Identity 'IT3C-JB-SEP2MDE' | ForEach-Object { Get-PSEntraIDMachine -DeviceId $_.DeviceId }

The MDE machine record(s) of a directory device.

### EXAMPLE 3

Get-PSEntraIDMachine -Filter "healthStatus eq 'Active'"

Machines whose sensor currently reports.

## PARAMETERS

### -DeviceId

The Entra ID device GUID (aadDeviceId) - server-side filter for the
machine records of a directory device.

```yaml
Type: System.Guid[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- AadDeviceId
ParameterSets:
- Name: DeviceId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

This parameter disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly,
but allows catching exceptions in calling scripts.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Filter

A raw OData $filter for the machines list.
The MDE API supports $filter
on computerDnsName, id, version, deviceValue, aadDeviceId, machineTags,
lastSeen, exposureLevel, onboardingStatus, lastIpAddress, healthStatus,
osPlatform, riskScore and rbacGroupId.
The string is passed through
verbatim - escape caller input before building it.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filter
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Identity

The MDE machine id (the hash issued by Defender for Endpoint).

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- MachineId
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

{{ Fill in the Description }}

### System.Guid[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.DefenderEndpoint.Machine

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

