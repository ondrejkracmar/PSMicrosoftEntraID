---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/19/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDUser
---

# Get-PSEntraIDUser

## SYNOPSIS

Get the properties of the specified user.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDUser -Identity <string[]> [-EnableException]
```

### Name

```
Get-PSEntraIDUser -Name <string[]> [-EnableException]
```

### CompanyName

```
Get-PSEntraIDUser -CompanyName <string[]> [-Disabled] [-EnableException]
```

### All

```
Get-PSEntraIDUser -All [-Disabled] [-EnableException]
```

### Filter

```
Get-PSEntraIDUser -Filter <string> [-AdvancedFilter] [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Get the properties of the specified user.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDUser -Identity user1@contoso.com

Get properties of Azure AD user user1@contoso.com

## PARAMETERS

### -AdvancedFilter

Switch advanced filter for filtering accounts in tenant/directory.

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

Return all accounts in tenant/directory.

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

### -CompanyName

CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: CompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Disabled

Return disabled accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: CompanyName
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

Filter expressions of accounts in tenant/directory.

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

UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- UserPrincipalName
- Mail
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

### -Name

DisplayName, GivenName, Surname of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Name
  Position: Named
  IsRequired: true
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

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Users.User

{{ Fill in the Description }}

## NOTES

Piping into Select-Object -First N logs a warning that is not a failure:

    WARNING: [<cmdlet>] Failed to: ...
| The pipeline has been stopped

The results are correct and complete.
Select-Object stops the pipeline once it
has what it asked for, and the next write throws PipelineStoppedException -
normal termination, reported as an error only because the write happens inside a
protected block.
Materialise first if the warning is in the way:

    $items = @(<cmdlet> ...)
    $items | Select-Object -First 3

or filter server-side with -Filter instead of trimming client-side.
Not silenced
on purpose: the only fix that works is to collect the whole result before
emitting any of it, which would cost streaming on every read.


## RELATED LINKS

{{ Fill in the related links here }}

