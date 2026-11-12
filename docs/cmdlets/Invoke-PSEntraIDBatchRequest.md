---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 11.12.2026
PlatyPS schema version: 2024-05-01
title: Invoke-PSEntraIDBatchRequest
---

# Invoke-PSEntraIDBatchRequest

## SYNOPSIS

Invokes Microsoft Graph batch requests from BatchRequestPayload objects and returns
the requests together with their responses.

## SYNTAX

### __AllParameterSets

```
Invoke-PSEntraIDBatchRequest [-InputObject] <BatchRequestPayload[]> [-EnableException] [-Force]
 [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function expects pipeline input of BatchRequestPayload objects (such as those
produced by New-PSEntraIDBatchRequest).
Each BatchRequestPayload contains up to 20
sub-requests.

The sub-requests of all payloads are sent through the module's batch engine: they are
packed into Graph $batch envelopes of 20, and Settings.Batch.ThrottleLimit envelopes
(default 4) are in flight at the same time.
The payloads are collected while the
pipeline delivers them and sent once it ends, so the first result appears only after
the last payload arrived.

Each sub-request is retried on its own: one answered 408, 429 or 5xx (except 501 and
505) is sent again after its own Retry-After (at most 5 minutes; otherwise 2^attempt
seconds with jitter), up to Settings.Batch.RetryCount times (default 5).
A POST
sub-request is sent again only on 429 and 503, where Graph says it did not carry it
out.
The envelope itself is never sent again as a whole, and nothing else retries.

For each payload one BatchResponsePayload is returned, in the order of the input:
    Requests  = the sub-requests of the payload
    Responses = one response per sub-request, in the order of the requests (Id, Status,
                Headers, Body)

A sub-request that failed for good keeps its response (with its status) in the output
and is also reported as ONE non-terminating error whose target is the request; the run
ends with ONE warning summarising failures and re-sends.
With -EnableException no error
records are written and the command throws at the end, after all results were returned.

Ctrl+C or a pipeline stopped downstream (Select-Object -First) cancels every envelope
still in flight.

## EXAMPLES

### EXAMPLE 1

$payloads | Invoke-PSEntraIDBatchRequest -EnableException

Sends one or more BatchRequestPayload objects (created by New-PSEntraIDBatchRequest)
to the Microsoft Graph $batch endpoint and returns BatchResponsePayload objects that
correlate the original requests with the responses returned by Graph.

## PARAMETERS

### -Confirm

Prompts for confirmation before the command makes a change.
-Confirm:$false
suppresses that prompt.

Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
prompts even alongside -Force, and the two are alternatives rather than a pair.

Left unbound, the decision belongs to this command's ConfirmImpact and the
session ConfirmPreference, which is the PowerShell default behaviour.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -EnableException

This parameter disables user-friendly warnings and enables the throwing of exceptions.
Less user friendly, but allows catching exceptions in calling scripts.

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

### -Force

Sends the batches without asking for confirmation.

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

### -InputObject

An array of BatchRequestPayload objects to be processed.
Each object
has a .Requests list containing up to 20 Request objects.

```yaml
Type: PSMicrosoftEntraID.Batch.BatchRequestPayload[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Enables the function to simulate what it will do instead of actually executing.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### PSMicrosoftEntraID.Batch.BatchRequestPayload[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.BatchResponsePayload

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

