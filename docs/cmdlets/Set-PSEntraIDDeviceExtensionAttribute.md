---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 09/02/2026
PlatyPS schema version: 2024-05-01
title: Set-PSEntraIDDeviceExtensionAttribute
---

# Set-PSEntraIDDeviceExtensionAttribute

## SYNOPSIS

Set or clear one extension attribute of an Entra ID device.

## SYNTAX

### InputObject (Default)

```
Set-PSEntraIDDeviceExtensionAttribute -InputObject <Device[]> -AttributeName <string>
 -Value <string> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### Identity

```
Set-PSEntraIDDeviceExtensionAttribute -Identity <string[]> -AttributeName <string> -Value <string>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### DeviceId

```
Set-PSEntraIDDeviceExtensionAttribute -DeviceId <guid[]> -AttributeName <string> -Value <string>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

PATCHes the extensionAttributes property of a directory device object
(Graph: Update device).
extensionAttributes is the one device property
an app-only caller may update - Device.ReadWrite.All suffices - and the
property dynamic device group rules can target
(device.extensionAttribute1..15).

The device can be addressed three ways: by piped device object, by the
directory object id, or by the device GUID (DeviceId - the same value
Defender for Endpoint reports as aadDeviceId), which Graph accepts
directly as devices(deviceId='...') without an object-id lookup.

## EXAMPLES

### EXAMPLE 1

Set-PSEntraIDDeviceExtensionAttribute -DeviceId $machine.AadDeviceId -AttributeName extensionAttribute10 -Value 'vip'

Writes the value into extensionAttribute10 of the device matched by its GUID.

### EXAMPLE 2

Get-PSEntraIDDevice -Identity 'IT3C-JB-SEP2MDE' | Set-PSEntraIDDeviceExtensionAttribute -AttributeName extensionAttribute10 -Value ''

Clears extensionAttribute10 on the device.

## PARAMETERS

### -AttributeName

Which attribute to write: extensionAttribute1 through extensionAttribute15.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts for confirmation before the command makes a change.
-Confirm:$false
suppresses that prompt.

Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
prompts even alongside -Force, and the two are alternatives rather than a pair.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -DeviceId

The device GUID(s) (device.deviceId / MDE aadDeviceId).

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
  ValueFromPipelineByPropertyName: false
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

### -Force

The Force switch instructs the command to which object the specific query is applied without asking for confirmation.

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

### -Identity

The directory object id(s) of the device (device.id).

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Device object(s) as returned by Get-PSEntraIDDevice.

```yaml
Type: PSMicrosoftEntraID.Devices.Device[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: InputObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PassThru

Instead of executing the request, return a PSMicrosoftEntraID.Batch.Request
for New-PSEntraIDBatchRequest / Invoke-PSEntraIDBatchRequest.

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

### -Value

The value to set.
An empty or null value CLEARS the attribute (Graph
clears with null; an empty string would be stored literally otherwise).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Enables the function to simulate what it will do instead of actually executing.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### PSMicrosoftEntraID.Devices.Device[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.Request

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

