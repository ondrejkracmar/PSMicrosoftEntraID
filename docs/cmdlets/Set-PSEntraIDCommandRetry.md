---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 11.12.2026
PlatyPS schema version: 2024-05-01
title: Set-PSEntraIDCommandRetry
---

# Set-PSEntraIDCommandRetry

## SYNOPSIS

Sets how often the module sends a failed Graph request again.

## SYNTAX

### __AllParameterSets

```
Set-PSEntraIDCommandRetry [[-RetryCount] <int>] [[-BatchRetryCount] <int>]
 [[-RetryWaitInSeconds] <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The module has one retry layer: Invoke-EntraRequest repeats a failed request
(Settings.Request.RetryCount) and the batch engine repeats a failed sub-request of a
$batch (Settings.Batch.RetryCount).
Repeated are throttling (429), 408 and server errors
(5xx except 501 and 505) and requests without an answer; a POST only on 429 and 503,
where the service says it did not carry it out.
The wait is the Retry-After the service
asks for (at most 5 minutes), otherwise 2^attempt seconds with jitter.

Only the values that are passed are changed; a call without parameters changes nothing.
The settings hold for the session; persist them with Register-PSFConfig.

## EXAMPLES

### EXAMPLE 1

Set-PSEntraIDCommandRetry -RetryCount 3

Sends a failed request at most three more times.

### EXAMPLE 2

Set-PSEntraIDCommandRetry -RetryCount 0 -BatchRetryCount 0

Turns retrying off: every request and every sub-request is sent once.

## PARAMETERS

### -BatchRetryCount

How often a failed sub-request of a $batch is sent again, 0 to 20
(Settings.Batch.RetryCount, default 5).

```yaml
Type: System.Int32
DefaultValue: 0
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

### -RetryCount

How often a failed request is sent again, 0 to 20 (Settings.Request.RetryCount, default 5).
0 sends every request once.

```yaml
Type: System.Int32
DefaultValue: 0
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

### -RetryWaitInSeconds

No longer used: the wait comes from the Retry-After of the answer or the exponential
backoff.
Accepted so existing scripts keep running; passing it writes a warning.

```yaml
Type: System.Int32
DefaultValue: 0
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

### System.Void

{{ Fill in the Description }}

## NOTES

Updates the settings PSMicrosoftEntraID.Settings.Request.RetryCount and
PSMicrosoftEntraID.Settings.Batch.RetryCount for the session.


## RELATED LINKS

{{ Fill in the related links here }}

