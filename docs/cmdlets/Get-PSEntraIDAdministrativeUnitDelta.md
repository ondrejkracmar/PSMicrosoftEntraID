---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/28/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDAdministrativeUnitDelta
---

# Get-PSEntraIDAdministrativeUnitDelta

## SYNOPSIS

Retrieves only the administrative units that changed since the previous call.

## SYNTAX

### __AllParameterSets

```
Get-PSEntraIDAdministrativeUnitDelta [[-DeltaSession] <hashtable>] [-MinimalDelta]
 [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Wraps Graph's directory/administrativeUnits/delta endpoint.
The first call with a given delta session
returns everything and stores a token in it; every call after that returns only
what changed since - created, updated, or removed.

This is the cheap way to stay current.
Re-reading a tenant of tens of thousands
of objects to find the handful that moved costs the same every time; a delta call
costs what actually changed.

Removed objects come back too, with ChangeType set to Deleted or Purged and
little more than their id populated - Graph does not resend the rest of something
that is gone.
That is the point: a full read cannot tell you what disappeared.

The delta session is a plain hashtable that lives only as long as your session.
For a scheduled task, persist it between runs with
Export-PSEntraIDDeltaSession and Import-PSEntraIDDeltaSession.

## EXAMPLES

### EXAMPLE 1

$delta = @{}
PS C:\> Get-PSEntraIDAdministrativeUnitDelta -DeltaSession $delta

First call: every administrative unit, and the token is stored in $delta.

### EXAMPLE 2

Get-PSEntraIDAdministrativeUnitDelta -DeltaSession $delta | Where-Object Removed

Subsequent call: only what changed, filtered down to what was removed.

### EXAMPLE 3

$delta = Import-PSEntraIDDeltaSession -Path .\administrativeunit.delta.json
PS C:\> Get-PSEntraIDAdministrativeUnitDelta -DeltaSession $delta
PS C:\> Export-PSEntraIDDeltaSession -Path .\administrativeunit.delta.json -DeltaSession $delta

The scheduled-task shape: load the token, ask for changes, save the new token.

## PARAMETERS

### -DeltaSession

Hashtable holding the delta token.
Pass an empty one on the first call and the
same one afterwards.
Omit it entirely to read everything without tracking.

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

Throw on failure instead of writing a warning.

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

### -MinimalDelta

Return only the properties that changed, plus the identifier, instead of the
whole object.
Reduces payload on large tenants.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnitDelta

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

