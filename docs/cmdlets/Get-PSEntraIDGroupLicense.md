---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 04/21/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDGroupLicense
---

# Get-PSEntraIDGroupLicense

## SYNOPSIS

Get assigned licenses of a group with service plan status details.

## SYNTAX

### Identity (Default)

```powershell
Get-PSEntraIDGroupLicense -Identity <string[]> [-EnableException] [<CommonParameters>]
```

### InputObject

```powershell
Get-PSEntraIDGroupLicense -InputObject <Group[]> [-EnableException] [<CommonParameters>]
```

## DESCRIPTION

Returns the licenses assigned to a group and resolves each SKU into a readable overview.
The output contains the SKU identifier, SKU part number, friendly product name and all service plans with a computed status of Enabled or Disabled.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PSEntraIDGroupLicense -Identity licensing-group
```

Get all licenses assigned to the group and show how many service plans are enabled and disabled for each SKU.

### EXAMPLE 2

```powershell
Get-PSEntraIDGroup -Identity licensing-group | Get-PSEntraIDGroupLicense
```

Pipe a group object into the cmdlet and return license details.

### EXAMPLE 3

```powershell
(Get-PSEntraIDGroupLicense -Identity licensing-group).ServicePlans
```

Inspect service plan details for the assigned licenses, including friendly names and Enabled or Disabled status.

## PARAMETERS

### -Identity

MailNickname, Mail or Id of the group attribute populated in tenant or directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- GroupId
- TeamId
- MailNickName
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

### -InputObject

PSMicrosoftEntraID.Groups.Group object in tenant or directory.

```yaml
Type: PSMicrosoftEntraID.Groups.Group[]
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

### -EnableException

This parameter disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly, but allows catching exceptions in calling scripts.

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

## OUTPUTS

### PSMicrosoftEntraID.Groups.AssignedLicenseDetail

One object per assigned SKU on the group.

### PSMicrosoftEntraID.Groups.AssignedLicenseServicePlanDetail

Nested objects available in the ServicePlans property.

## NOTES

The cmdlet resolves readable SKU and service plan names using subscribed license metadata and the built-in license identifier catalog.