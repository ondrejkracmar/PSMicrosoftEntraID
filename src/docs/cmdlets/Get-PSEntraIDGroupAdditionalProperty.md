---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDGroupAdditionalProperty
---

# Get-PSEntraIDGroupAdditionalProperty

## SYNOPSIS

Get the properties and relationships of a group or the team, and to the unified group which backs the team.

## SYNTAX

### InputObject (Default)

```
Get-PSEntraIDGroupAdditionalProperty -InputObject <Group[]> [-EnableException] [<CommonParameters>]
```

### Identity

```
Get-PSEntraIDGroupAdditionalProperty -Identity <string[]> [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet gets properties and relationships of a group or the team, and to the unified group which backs the team.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDGroupProperty -Identity group1@contoso.com

Get theadditional properties and relationships of a group group1@contoso.com

## PARAMETERS

### -EnableException

This parameters disables user-friendly warnings and enables the throwing of exceptions.
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

### -Identity

MailNickName or Id of group or team.

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
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

PSMicrosoftEntraID.Groups.Group object in tenant/directory.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### PSMicrosoftEntraID.Groups.Group[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Groups.GroupAdditionalProperty

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

