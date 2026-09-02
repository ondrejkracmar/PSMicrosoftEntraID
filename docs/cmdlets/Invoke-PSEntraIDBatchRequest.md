---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 09/02/2026
PlatyPS schema version: 2024-05-01
title: Invoke-PSEntraIDBatchRequest
---

# Invoke-PSEntraIDBatchRequest

## SYNOPSIS

Invokes a Microsoft Graph batch request using an array of BatchRequestPayload objects,
then returns a combined object with both the requests and responses.

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

This function expects pipeline input of BatchRequestPayload objects
(such as those produced by New-PSEntraIDBatchRequest).
Each BatchRequestPayload contains up to 20 sub-requests (ID=1..20).

For each batch payload, this function can validate the requests (Test-PSMicrosoftEntraIDBatchRequest),
then send them to the Graph batch endpoint (via Invoke-EntraRequest).
It captures the Graph response (which typically has a 'responses' array)
and outputs a combined PSCustomObject with:
    requests   = the sub-requests
    responses  = the sub-responses from Graph

This allows a subsequent cmdlet (e.g.
Invoke-PSMicrosoftEntraIDBatchResponse) to correlate them by id.

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

The Force switch instructs the command to stop processing before any changes are made
and prompt for confirmation (depending on your logic in the code).
When used, you can step through changes to ensure only specific objects are modified.

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

