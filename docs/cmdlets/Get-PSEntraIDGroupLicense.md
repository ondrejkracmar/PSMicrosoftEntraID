---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/28/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDGroupLicense
---

# Get-PSEntraIDGroupLicense

## SYNOPSIS

Get assigned licenses of a group with service plan status details.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDGroupLicense -Identity <string[]> [-EnableException]
```

### InputObject

```
Get-PSEntraIDGroupLicense -InputObject <Group[]> [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Get assigned licenses of a group with resolved SKU names and service plan status details.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDGroupLicense -Identity licensing-group

Get assigned group licenses with enabled and disabled service plans.

## PARAMETERS

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

### -Identity

MailNickname, Mail or Id of the group attribute populated in tenant/directory.

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
  ValueFromPipelineByPropertyName: false
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

### PSMicrosoftEntraID.Groups.AssignedLicenseDetail

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

