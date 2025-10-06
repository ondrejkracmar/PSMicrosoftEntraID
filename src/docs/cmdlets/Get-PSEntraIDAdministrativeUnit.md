---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDAdministrativeUnit
---

# Get-PSEntraIDAdministrativeUnit

## SYNOPSIS

Get the properties of the specified administrative unit.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDAdministrativeUnit -Identity <string[]> [-EnableException] [<CommonParameters>]
```

### DisplayName

```
Get-PSEntraIDAdministrativeUnit -DisplayName <string[]> [-EnableException] [<CommonParameters>]
```

### Filter

```
Get-PSEntraIDAdministrativeUnit -Filter <string> [-AdvancedFilter] [-EnableException]
 [<CommonParameters>]
```

### All

```
Get-PSEntraIDAdministrativeUnit -All [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Get the properties of the specified administrative unit.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDAdministrativeUnit -Identity "Marketing AU"

Get properties of administrative unit "Marketing AU"

### EXAMPLE 2

Get-PSEntraIDAdministrativeUnit -All

Get all administrative units in the tenant

### EXAMPLE 3

Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

Get administrative units using OData filter

## PARAMETERS

### -AdvancedFilter

Switch advanced filter for filtering administrative units in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filter
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -All

Return all administrative units in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

DisplayName of the administrative unit attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DisplayName
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

Filter expressions of administrative units in tenant/directory.

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

DisplayName or Id of the administrative unit attribute populated in tenant/directory.

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

## OUTPUTS

### PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

