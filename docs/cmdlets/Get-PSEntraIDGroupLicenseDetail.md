---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 04/22/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDGroupLicenseDetail
---

# Get-PSEntraIDGroupLicenseDetail

## SYNOPSIS

Return details for licenses that are assigned to a group.

## SYNTAX

### InputObject (Default)

```powershell
Get-PSEntraIDGroupLicenseDetail -InputObject <Group[]> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

### Identity

```powershell
Get-PSEntraIDGroupLicenseDetail -Identity <string[]> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## DESCRIPTION

Return details for licenses that are assigned to a group.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PSEntraIDGroupLicenseDetail -Identity licensing-group
```

Get Office 365 subscriptions with their service plans of specific group.

### EXAMPLE 2

```powershell
Get-PSEntraIDGroup -Identity licensing-group | Get-PSEntraIDGroupLicenseDetail
```

Pipe a group object into the cmdlet and return detailed license assignments.

## PARAMETERS

### -AdvancedFilter

Returns the full assigned-license detail including expanded service plan information instead of the simplified default projection.

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