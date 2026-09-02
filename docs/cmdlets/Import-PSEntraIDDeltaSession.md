---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 09/02/2026
PlatyPS schema version: 2024-05-01
title: Import-PSEntraIDDeltaSession
---

# Import-PSEntraIDDeltaSession

## SYNOPSIS

Loads a delta session saved by Export-PSEntraIDDeltaSession.

## SYNTAX

### __AllParameterSets

```
Import-PSEntraIDDeltaSession [-Path] <string> [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns a hashtable ready to hand to a delta cmdlet's -DeltaSession parameter.

A missing file is not an error: the first run of a scheduled task has nothing to
load, and an empty session is exactly what a first run needs.
That keeps the
calling script to three lines with no existence check.

Doing this by hand is the trap this exists for.
ConvertFrom-Json returns a
PSCustomObject, and -DeltaSession takes a hashtable, so the obvious round-trip
fails at the point of use rather than at the point of the mistake.

## EXAMPLES

### EXAMPLE 1

$delta = Import-PSEntraIDDeltaSession -Path .\users.delta.json
PS C:\> Get-PSEntraIDUserDelta -DeltaSession $delta
PS C:\> Export-PSEntraIDDeltaSession -DeltaSession $delta -Path .\users.delta.json

The whole scheduled-task pattern: load, ask for changes, save.

## PARAMETERS

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

### -Path

The file written by Export-PSEntraIDDeltaSession.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

## OUTPUTS

### System.Collections.Hashtable

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

