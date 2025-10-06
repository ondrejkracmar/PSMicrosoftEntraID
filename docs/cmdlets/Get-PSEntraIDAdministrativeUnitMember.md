---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDAdministrativeUnitMember
---

# Get-PSEntraIDAdministrativeUnitMember

## SYNOPSIS

Get members of an administrative unit.

## SYNTAX

### InputObject (Default)

```
Get-PSEntraIDAdministrativeUnitMember -InputObject <AdministrativeUnit[]> [-Filter <string>]
 [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

### Identity

```
Get-PSEntraIDAdministrativeUnitMember -Identity <string[]> [-Filter <string>] [-AdvancedFilter]
 [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This cmdlet gets members of an administrative unit.
Administrative units can contain users, groups, and devices as members.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDAdministrativeUnitMember -Identity "Marketing AU"

Get members of administrative unit "Marketing AU"

### EXAMPLE 2

Get-PSEntraIDAdministrativeUnit -DisplayName "Finance AU" | Get-PSEntraIDAdministrativeUnitMember

Get members of administrative unit "Finance AU" using pipeline

### EXAMPLE 3

Get-PSEntraIDAdministrativeUnitMember -Identity "HR AU" -Filter "displayName startswith 'John'"

Get members of administrative unit "HR AU" where display name starts with 'John'

## PARAMETERS

### -AdvancedFilter

Switch advanced filter for filtering members in the administrative unit.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -Filter

Filter expressions for members in the administrative unit.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObject
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

DisplayName or Id of the administrative unit.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- AdministrativeUnitId
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

PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

```yaml
Type: PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit[]
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

### PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Users.User

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

