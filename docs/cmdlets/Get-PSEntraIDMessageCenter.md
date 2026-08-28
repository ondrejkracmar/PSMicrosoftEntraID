---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/28/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDMessageCenter
---

# Get-PSEntraIDMessageCenter

## SYNOPSIS

Retrieves announcements from Microsoft 365 Message Center via Graph API using .NET deserialization.

## SYNTAX

### __AllParameterSets

```
Get-PSEntraIDMessageCenter [[-Service] <string[]>] [[-Category] <string[]>] [[-Severity] <string[]>]
 [[-PublishedAfter] <datetime>] [[-PublishedBefore] <datetime>] [-EnableException]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Queries Microsoft Graph API for service announcement messages, deserializes them using .NET and filters them by parameters.
Uses Graph API $filter where supported (category, severity) and applies service and datetime filtering locally.
Requires delegated Graph permission: ServiceMessage.Read.All.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDMessageCenter -Service "Microsoft Teams" -Category feature -PublishedAfter (Get-Date).AddDays(-7)

Returns Microsoft Teams feature announcements published in the last 7 days.

### EXAMPLE 2

Get-PSEntraIDMessageCenter -Service All -Severity high

Returns all high severity Message Center announcements across all services.

## PARAMETERS

### -Category

Filters messages by category (feature, retire, stayInformed, planForChange).

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

Enables throwing terminating exceptions if an error occurs during API call.

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

### -PublishedAfter

Filters messages published after this UTC datetime (evaluated locally).

```yaml
Type: System.DateTime
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PublishedBefore

Filters messages published before this UTC datetime (evaluated locally).

```yaml
Type: System.DateTime
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Service

One or more Microsoft 365 services to filter messages by.
Use 'All' to return all services (no filtering).

```yaml
Type: System.String[]
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

### -Severity

Filters messages by severity (normal, high, critical).

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
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

### PSMicrosoftEntraID.MessageCenter.Message[]

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

